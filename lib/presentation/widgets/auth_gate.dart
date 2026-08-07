import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';

/// Google session → profile ensure → home / login.
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
            return const MainShellScreen();
          }
          if (profile.status == ProfileLoadStatus.error) {
            return _ProfileErrorScaffold(
              message: profile.errorMessage ??
                  'Profil hazırlanamadı. Lütfen tekrar dene.',
              onRetry: () =>
                  ref.read(currentProfileProvider.notifier).ensureProfile(),
              onSignOut: () => ref.read(authProvider.notifier).signOut(),
            );
          }
          return const _BootScaffold(label: 'Profil hazırlanıyor...');
        }(),
    };

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
          '${auth.status.name}-${profile.status.name}-${profile.isReady}',
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

class _ProfileErrorScaffold extends StatelessWidget {
  const _ProfileErrorScaffold({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTop,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 48,
                color: AppColors.accentDeep,
              ),
              const SizedBox(height: 16),
              Text(
                'Profil açılamadı',
                style: AppTypography.brand(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.title(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Tekrar Dene',
                    style: AppTypography.body(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSignOut,
                child: Text(
                  'Çıkış Yap',
                  style: AppTypography.body(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
