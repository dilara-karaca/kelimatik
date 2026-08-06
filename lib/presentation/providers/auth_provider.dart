import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/auth_service.dart';
import '../../domain/models/auth_failure.dart';
import 'dependency_providers.dart';

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

  /// Ready for profile/settings UI; not exposed in the UI yet.
  Future<void> signOut() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _auth.signOut();
      state = const AppAuthState(status: AppAuthStatus.unauthenticated);
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Çıkış yapılamadı. Lütfen tekrar dene.',
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }
}
