import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/character_onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';
import 'app_error_view.dart';

/// Google session → profile ensure → onboarding / home / login.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = ref.watch(currentProfileProvider);

    final child = switch (auth.status) {
      AppAuthStatus.unknown => const _BootScaffold(),
      AppAuthStatus.unauthenticated => const LoginScreen(),
      AppAuthStatus.authenticated => () {
          if (profile.isReady) {
            final p = profile.profile!;
            if (p.needsOnboarding) {
              return const CharacterOnboardingScreen();
            }
            return const MainShellScreen();
          }
          if (profile.status == ProfileLoadStatus.error) {
            final info = AppErrorInfo.from(profile.errorMessage);
            // Prefer offline / load titles; keep profile-specific fallback.
            final resolved = info.kind == AppErrorKind.offline
                ? AppErrorInfo.offline
                : const AppErrorInfo(
                    kind: AppErrorKind.loadFailed,
                    title: 'Veri yüklenemedi',
                    message: 'Profilini yükleyemedik.\nTekrar dene.',
                  );
            return Scaffold(
              backgroundColor: AppColors.backgroundTop,
              body: SafeArea(
                child: AppErrorView(
                  info: resolved,
                  onRetry: () =>
                      ref.read(currentProfileProvider.notifier).ensureProfile(),
                  secondaryLabel: 'Çıkış Yap',
                  onSecondary: () =>
                      ref.read(authProvider.notifier).signOut(),
                ),
              ),
            );
          }
          return const _BootScaffold(label: 'Profil hazırlanıyor...');
        }(),
    };

    final onboardingKey =
        profile.profile?.needsOnboarding == true ? 'need' : 'done';

    return AnimatedSwitcher(
      duration: AppConstants.pageTransition,
      reverseDuration: AppConstants.pageReverseTransition,
      switchInCurve: AppConstants.pageCurve,
      switchOutCurve: AppConstants.pageReverseCurve,
      transitionBuilder: (widget, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: widget,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(
          '${auth.status.name}-${profile.status.name}-${profile.isReady}-$onboardingKey',
        ),
        child: child,
      ),
    );
  }
}

class _BootScaffold extends StatelessWidget {
  const _BootScaffold({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTop,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 3,
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(
                label!,
                style: AppTypography.title(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
