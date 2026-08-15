import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_characters.dart';
import 'profile_model.dart';

/// User-facing failure for profile / Supabase data operations.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message, {this.retryable = false});

  final String message;
  final bool retryable;

  @override
  String toString() => message;
}

/// CRUD helpers for `public.profiles`.
class ProfileService {
  ProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _random = Random();

  static const _table = 'profiles';
  static const _maxAttempts = 3;

  User? get _user => _client.auth.currentUser;

  /// Returns the signed-in user's profile, or null if missing.
  Future<Profile?> getCurrentProfile() => _withRetry(_getCurrentProfileOnce);

  Future<Profile?> _getCurrentProfileOnce() async {
    final user = _user;
    if (user == null) return null;

    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) return null;
      return Profile.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw ProfileFailure(_mapPostgrestError(error));
    } on AuthException catch (error) {
      throw ProfileFailure(_mapAuthError(error), retryable: true);
    } catch (error, stack) {
      debugPrint('getCurrentProfile failed: $error\n$stack');
      throw ProfileFailure(
        _mapUnknownError(error),
        retryable: _isTransient(error),
      );
    }
  }

  /// Inserts a profile for the current auth user (first login).
  ///
  /// No-ops if a profile already exists.
  Future<void> createProfile() async {
    final user = _user;
    if (user == null) {
      throw const ProfileFailure('Oturum bulunamadı. Tekrar giriş yap.');
    }

    final existing = await _getCurrentProfileOnce();
    if (existing != null) return;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final displayName = _pickDisplayName(meta, user);
    final avatarUrl = _pickAvatarUrl(meta);

    PostgrestException? lastError;
    for (var attempt = 0; attempt < 8; attempt++) {
      final username = await _generateUniqueUsername(displayName, attempt);
      try {
        await _client.from(_table).insert({
          'id': user.id,
          'username': username,
          'display_name': displayName,
          'avatar_url': avatarUrl,
        });
        return;
      } on PostgrestException catch (error) {
        lastError = error;
        // Unique username race / collision — try another suffix.
        if (error.code == '23505' &&
            (error.message.toLowerCase().contains('username') ||
                error.details?.toString().toLowerCase().contains('username') ==
                    true)) {
          continue;
        }
        // Profile row already exists for this user id.
        if (error.code == '23505') {
          final again = await _getCurrentProfileOnce();
          if (again != null) return;
        }
        throw ProfileFailure(_mapPostgrestError(error));
      } on ProfileFailure {
        rethrow;
      } on AuthException catch (error) {
        throw ProfileFailure(_mapAuthError(error), retryable: true);
      } catch (error, stack) {
        debugPrint('createProfile failed: $error\n$stack');
        throw ProfileFailure(
          'Profil oluşturulamadı. Lütfen tekrar dene.',
          retryable: _isTransient(error),
        );
      }
    }

    if (lastError != null) {
      throw ProfileFailure(_mapPostgrestError(lastError));
    }
    throw const ProfileFailure(
      'Benzersiz kullanıcı adı üretilemedi. Lütfen tekrar dene.',
    );
  }

  /// Partial update for the signed-in user's profile.
  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? selectedCharacter,
    bool? onboardingCompleted,
    int? xp,
    int? level,
    int? correctCount,
    int? wrongCount,
    int? streak,
  }) async {
    final user = _user;
    if (user == null) {
      throw const ProfileFailure('Oturum bulunamadı. Tekrar giriş yap.');
    }

    final payload = <String, dynamic>{};
    if (username != null) {
      final trimmed = username.trim();
      final validationError = UsernameRules.validate(trimmed);
      if (validationError != null) {
        throw ProfileFailure(validationError);
      }
      payload['username'] = trimmed;
    }
    if (displayName != null) payload['display_name'] = displayName.trim();
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl.trim();
    if (selectedCharacter != null) {
      payload['selected_character'] = selectedCharacter.trim();
    }
    if (onboardingCompleted != null) {
      payload['onboarding_completed'] = onboardingCompleted;
    }
    if (xp != null) payload['xp'] = xp;
    if (level != null) payload['level'] = level;
    if (correctCount != null) payload['correct_count'] = correctCount;
    if (wrongCount != null) payload['wrong_count'] = wrongCount;
    if (streak != null) payload['streak'] = streak;

    if (payload.isEmpty) return;

    try {
      await _client.from(_table).update(payload).eq('id', user.id);
    } on PostgrestException catch (error) {
      throw ProfileFailure(_mapPostgrestError(error));
    } on AuthException catch (error) {
      throw ProfileFailure(_mapAuthError(error), retryable: true);
    } catch (error, stack) {
      debugPrint('updateProfile failed: $error\n$stack');
      throw ProfileFailure(
        'Profil güncellenemedi. Lütfen tekrar dene.',
        retryable: _isTransient(error),
      );
    }
  }

  /// True if [username] is free or already owned by the current user.
  Future<bool> isUsernameAvailable(String username) async {
    final user = _user;
    if (user == null) {
      throw const ProfileFailure('Oturum bulunamadı. Tekrar giriş yap.');
    }

    try {
      final row = await _client
          .from(_table)
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (row == null) return true;
      return row['id'] == user.id;
    } on PostgrestException catch (error) {
      throw ProfileFailure(_mapPostgrestError(error));
    } on AuthException catch (error) {
      throw ProfileFailure(_mapAuthError(error), retryable: true);
    } catch (error, stack) {
      debugPrint('isUsernameAvailable failed: $error\n$stack');
      throw ProfileFailure(
        'Kullanıcı adı kontrol edilemedi. Lütfen tekrar dene.',
        retryable: _isTransient(error),
      );
    }
  }

  /// Reloads the current profile from Supabase.
  Future<Profile?> refreshProfile() => getCurrentProfile();

  /// Ensures a profile exists for the current session (get-or-create).
  Future<Profile> ensureProfile() {
    return _withRetry(() async {
      final existing = await _getCurrentProfileOnce();
      if (existing != null) return existing;

      await createProfile();
      final created = await _getCurrentProfileOnce();
      if (created == null) {
        throw const ProfileFailure(
          'Profil oluşturuldu ama okunamadı. Lütfen tekrar dene.',
          retryable: true,
        );
      }
      return created;
    });
  }

  String _pickDisplayName(Map<String, dynamic> meta, User user) {
    final candidates = [
      meta['full_name'],
      meta['name'],
      meta['display_name'],
      user.email?.split('@').first,
    ];
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'Oyuncu';
  }

  String? _pickAvatarUrl(Map<String, dynamic> meta) {
    final candidates = [meta['avatar_url'], meta['picture']];
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<String> _generateUniqueUsername(String displayName, int attempt) async {
    final base = _slugify(displayName);
    if (attempt == 0) return base;
    final suffix = 1000 + _random.nextInt(9000);
    return '$base$suffix';
  }

  String _slugify(String input) {
    var value = input.trim().toLowerCase();
    const map = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i̇': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'â': 'a',
      'î': 'i',
      'û': 'u',
    };
    map.forEach((from, to) {
      value = value.replaceAll(from, to);
    });
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (value.length > 18) value = value.substring(0, 18);
    if (value.isEmpty) value = 'oyuncu';
    return value;
  }

  Future<T> _withRetry<T>(Future<T> Function() action) async {
    Object? lastError;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        return await action();
      } on ProfileFailure catch (failure) {
        lastError = failure;
        if (!failure.retryable || attempt >= _maxAttempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } catch (error) {
        lastError = error;
        if (!_isTransient(error) || attempt >= _maxAttempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    final error = lastError;
    if (error is ProfileFailure) throw error;
    throw ProfileFailure(_mapUnknownError(error ?? 'unknown'));
  }

  bool _isTransient(Object error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is AuthException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup') ||
        text.contains('connection closed') ||
        text.contains('clientexception');
  }

  String _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.';
    }
    if (message.contains('jwt') ||
        message.contains('session') ||
        message.contains('expired') ||
        message.contains('refresh')) {
      return 'Oturum süresi dolmuş olabilir. Tekrar giriş yap.';
    }
    return 'Oturum doğrulanamadı. Lütfen tekrar dene.';
  }

  String _mapUnknownError(Object error) {
    if (_isTransient(error)) {
      return 'Profil yüklenemedi. İnternet bağlantını kontrol edip tekrar dene.';
    }
    return 'Profil yüklenemedi. Lütfen tekrar dene.';
  }

  String _mapPostgrestError(PostgrestException error) {
    final code = error.code;
    final message = (error.message).toLowerCase();

    if (code == '23505' || message.contains('duplicate')) {
      return 'Bu kullanıcı adı zaten kullanılıyor.';
    }
    if (code == '42501' ||
        message.contains('permission') ||
        message.contains('rls')) {
      return 'Profil erişim izni yok. Supabase RLS ayarlarını kontrol et.';
    }
    if (code == '42P01' || message.contains('does not exist')) {
      return 'profiles tablosu bulunamadı. SQL migration’ı çalıştır.';
    }
    if (message.contains('jwt') || message.contains('auth')) {
      return 'Oturum süresi dolmuş olabilir. Tekrar giriş yap.';
    }
    if (message.contains('network') || message.contains('timeout')) {
      return 'Bağlantı hatası. İnternetini kontrol edip tekrar dene.';
    }
    return 'Profil işlemi başarısız: ${error.message}';
  }
}
