import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/user_progress_sync_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/user_progress_bootstrap.dart';
import 'profile_model.dart';
import 'profile_service.dart';

enum ProfileLoadStatus {
  idle,
  loading,
  ready,
  error,
}

class ProfileState {
  const ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  final ProfileLoadStatus status;
  final Profile? profile;
  final String? errorMessage;

  bool get isReady => status == ProfileLoadStatus.ready && profile != null;

  ProfileState copyWith({
    ProfileLoadStatus? status,
    Profile? profile,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const idle = ProfileState(status: ProfileLoadStatus.idle);
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// App-wide current user profile (get-or-create after auth).
final currentProfileProvider =
    NotifierProvider<CurrentProfileNotifier, ProfileState>(
  CurrentProfileNotifier.new,
);

class CurrentProfileNotifier extends Notifier<ProfileState> {
  Future<void>? _inFlightEnsure;

  @override
  ProfileState build() {
    ref.listen<AppAuthState>(authProvider, (previous, next) {
      if (next.status == AppAuthStatus.authenticated) {
        // Only after cold-start bootstrap (unknown → authenticated).
        if (previous?.status != AppAuthStatus.authenticated) {
          ensureProfile();
        }
      } else if (next.status == AppAuthStatus.unauthenticated) {
        _inFlightEnsure = null;
        state = ProfileState.idle;
      }
    });

    final auth = ref.read(authProvider);
    if (auth.status == AppAuthStatus.authenticated) {
      Future.microtask(ensureProfile);
    }

    return ProfileState.idle;
  }

  ProfileService get _service => ref.read(profileServiceProvider);

  Future<void> ensureProfile() async {
    final existing = _inFlightEnsure;
    if (existing != null) return existing;

    final future = _ensureProfileBody();
    _inFlightEnsure = future;
    try {
      await future;
    } finally {
      if (identical(_inFlightEnsure, future)) {
        _inFlightEnsure = null;
      }
    }
  }

  Future<void> _ensureProfileBody() async {
    state = state.copyWith(
      status: ProfileLoadStatus.loading,
      clearError: true,
    );
    try {
      final profile = await _service.ensureProfile();
      if (!profile.needsOnboarding) {
        await hydrateUserProgressFromCloud(ref: ref, profile: profile);
        final refreshed = await _service.refreshProfile();
        state = ProfileState(
          status: ProfileLoadStatus.ready,
          profile: refreshed ?? profile,
        );
        return;
      }
      state = ProfileState(
        status: ProfileLoadStatus.ready,
        profile: profile,
      );
    } on ProfileFailure catch (failure) {
      state = ProfileState(
        status: ProfileLoadStatus.error,
        errorMessage: failure.message,
      );
    } on UserProgressSyncFailure catch (failure) {
      state = ProfileState(
        status: ProfileLoadStatus.error,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = const ProfileState(
        status: ProfileLoadStatus.error,
        errorMessage: 'Profil hazırlanamadı. Lütfen tekrar dene.',
      );
    }
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(
      status: ProfileLoadStatus.loading,
      clearError: true,
    );
    try {
      final profile = await _service.refreshProfile();
      if (profile == null) {
        await ensureProfile();
        return;
      }
      state = ProfileState(
        status: ProfileLoadStatus.ready,
        profile: profile,
      );
    } on ProfileFailure catch (failure) {
      state = ProfileState(
        status: ProfileLoadStatus.error,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = const ProfileState(
        status: ProfileLoadStatus.error,
        errorMessage: 'Profil yenilenemedi. Lütfen tekrar dene.',
      );
    }
  }

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
    try {
      await _service.updateProfile(
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        selectedCharacter: selectedCharacter,
        onboardingCompleted: onboardingCompleted,
        xp: xp,
        level: level,
        correctCount: correctCount,
        wrongCount: wrongCount,
        streak: streak,
      );
      await refreshProfile();
    } on ProfileFailure catch (failure) {
      state = state.copyWith(
        status: ProfileLoadStatus.error,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: ProfileLoadStatus.error,
        errorMessage: 'Profil güncellenemedi. Lütfen tekrar dene.',
      );
    }
  }

  /// Completes character + username onboarding without leaving AuthGate ready.
  ///
  /// Returns an error message on failure; null on success.
  Future<String?> completeOnboarding({
    required String username,
    required String selectedCharacter,
  }) async {
    try {
      final available = await _service.isUsernameAvailable(username);
      if (!available) {
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      }
      await _service.updateProfile(
        username: username,
        selectedCharacter: selectedCharacter,
        onboardingCompleted: true,
      );
      final profile = await _service.refreshProfile();
      if (profile == null) {
        return 'Profil güncellenemedi. Lütfen tekrar dene.';
      }
      try {
        await hydrateUserProgressFromCloud(ref: ref, profile: profile);
      } on UserProgressSyncFailure catch (failure) {
        return failure.message;
      }
      state = ProfileState(
        status: ProfileLoadStatus.ready,
        profile: profile,
      );
      return null;
    } on ProfileFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'Profil güncellenemedi. Lütfen tekrar dene.';
    }
  }

  /// Updates username and/or character on the remote `profiles` row.
  ///
  /// Returns an error message on failure; null on success.
  Future<String?> updateIdentity({
    String? username,
    String? selectedCharacter,
  }) async {
    try {
      if (username != null) {
        final available = await _service.isUsernameAvailable(username);
        if (!available) {
          return 'Bu kullanıcı adı zaten kullanılıyor.';
        }
      }
      await _service.updateProfile(
        username: username,
        selectedCharacter: selectedCharacter,
      );
      final profile = await _service.refreshProfile();
      if (profile == null) {
        return 'Profil güncellenemedi. Lütfen tekrar dene.';
      }
      state = ProfileState(
        status: ProfileLoadStatus.ready,
        profile: profile,
      );
      return null;
    } on ProfileFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'Profil güncellenemedi. Lütfen tekrar dene.';
    }
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }
}
