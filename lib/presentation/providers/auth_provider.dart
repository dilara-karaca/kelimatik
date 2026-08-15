import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/user_local_cache.dart';
import '../../domain/models/auth_failure.dart';
import 'catalog_providers.dart';
import 'dependency_providers.dart';
import 'lives_provider.dart';
import 'stats_provider.dart';

enum AppAuthStatus {
  /// Initial session check in progress.
  unknown,

  authenticated,
  unauthenticated,
}

class AppAuthState {
  const AppAuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isBusy = false,
  });

  final AppAuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isBusy;

  AppAuthState copyWith({
    AppAuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearError = false,
    bool? isBusy,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBusy: isBusy ?? this.isBusy,
    );
  }

  static const unknown = AppAuthState(status: AppAuthStatus.unknown);
}

final authProvider =
    NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppAuthState> {
  @override
  AppAuthState build() {
    final auth = ref.read(authServiceProvider);

    final sub = auth.onAuthStateChange.listen((data) {
      // Ignore stream events until cold-start bootstrap finishes; otherwise
      // initialSession can mark authenticated before the JWT is refreshed.
      if (state.status == AppAuthStatus.unknown) return;

      final next = data.session;
      if (next == null) {
        state = const AppAuthState(status: AppAuthStatus.unauthenticated);
      } else {
        state = AppAuthState(
          status: AppAuthStatus.authenticated,
          user: next.user,
        );
      }
    });

    ref.onDispose(sub.cancel);

    // Cold start: stay on boot UI until session is refreshed (or confirmed).
    Future.microtask(_bootstrapSession);

    return AppAuthState.unknown;
  }

  Future<void> _bootstrapSession() async {
    final auth = ref.read(authServiceProvider);
    try {
      final session = await auth.ensureFreshSession();
      if (!ref.mounted) return;
      if (session == null) {
        state = const AppAuthState(status: AppAuthStatus.unauthenticated);
      } else {
        state = AppAuthState(
          status: AppAuthStatus.authenticated,
          user: session.user,
        );
      }
    } catch (_) {
      if (!ref.mounted) return;
      final fallback = auth.currentSession;
      state = fallback == null
          ? const AppAuthState(status: AppAuthStatus.unauthenticated)
          : AppAuthState(
              status: AppAuthStatus.authenticated,
              user: fallback.user,
            );
    }
  }

  AuthService get _auth => ref.read(authServiceProvider);

  Future<void> signInWithGoogle() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _auth.signInWithGoogle();
      // Session stream updates [state]; keep busy false after success.
      state = state.copyWith(isBusy: false, clearError: true);
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        isBusy: false,
        status: AppAuthStatus.unauthenticated,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        status: AppAuthStatus.unauthenticated,
        errorMessage: 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.',
      );
    }
  }

  Future<void> signOut() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _auth.signOut();
    } on AuthFailure {
      // Still force local logout so AuthGate can show login.
    } catch (_) {
      // Ignore — local unauthenticated below is the source of truth for UI.
    }
    if (!ref.mounted) return;
    await _clearLocalUserState();
    state = const AppAuthState(status: AppAuthStatus.unauthenticated);
  }

  /// Permanently deletes the account in Supabase Auth + related DB rows.
  Future<String?> deleteAccount() async {
    if (state.isBusy) return 'İşlem devam ediyor. Lütfen bekle.';
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _auth.deleteAccount();
      if (!ref.mounted) return null;
      await _clearLocalUserState();
      state = const AppAuthState(status: AppAuthStatus.unauthenticated);
      return null;
    } on AuthFailure catch (failure) {
      if (!ref.mounted) return failure.message;
      state = state.copyWith(isBusy: false, errorMessage: failure.message);
      return failure.message;
    } catch (_) {
      const message = 'Hesap silinemedi. Lütfen tekrar dene.';
      if (!ref.mounted) return message;
      state = state.copyWith(isBusy: false, errorMessage: message);
      return message;
    }
  }

  Future<void> _clearLocalUserState() async {
    await clearUserProgressLocalCache(ref.read(sharedPreferencesProvider));
    ref.invalidate(statsProvider);
    ref.invalidate(livesProvider);
    ref.invalidate(bestStreakProvider);
    ref.invalidate(dailyStreakProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(mistakesProvider);
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }
}
