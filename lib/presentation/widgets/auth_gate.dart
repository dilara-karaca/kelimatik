import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error.dart';
import '../../features/profile/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/character_onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';
import 'app_error_view.dart';
import 'launch_video_splash.dart';

/// Google session → profile ensure → onboarding / home / login.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  static const _fadeDuration = Duration(milliseconds: 250);

  late final LaunchVideoSplash _splash;
  var _videoFinished = false;
  var _splashVisible = true;
  Timer? _maxHold;

  @override
  void initState() {
    super.initState();
    _splash = LaunchVideoSplash(onFinished: _onVideoFinished);
    _maxHold = Timer(const Duration(seconds: 6), _onVideoFinished);
  }

  @override
  void dispose() {
    _maxHold?.cancel();
    super.dispose();
  }

  void _onVideoFinished() {
    if (!mounted || _videoFinished) return;
    _maxHold?.cancel();
    setState(() => _videoFinished = true);
  }

  bool _hasDestination(AppAuthState auth, ProfileState profile) {
    if (auth.status == AppAuthStatus.unauthenticated) return true;
    if (auth.status != AppAuthStatus.authenticated) return false;
    return profile.isReady || profile.status == ProfileLoadStatus.error;
  }

  Widget _destination(AppAuthState auth, ProfileState profile) {
    switch (auth.status) {
      case AppAuthStatus.unknown:
        return const SizedBox.shrink();
      case AppAuthStatus.unauthenticated:
        return const LoginScreen();
      case AppAuthStatus.authenticated:
        if (profile.isReady) {
          final p = profile.profile!;
          if (p.needsOnboarding) {
            return const CharacterOnboardingScreen();
          }
          return const MainShellScreen();
        }
        if (profile.status == ProfileLoadStatus.error) {
          final info = AppErrorInfo.from(profile.errorMessage);
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
                onSecondary: () => ref.read(authProvider.notifier).signOut(),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profile = ref.watch(currentProfileProvider);
    final destinationReady = _hasDestination(auth, profile);
    final showApp = destinationReady && _videoFinished;
    final onboardingKey =
        profile.profile?.needsOnboarding == true ? 'need' : 'done';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showApp)
          KeyedSubtree(
            key: ValueKey<String>(
              '${auth.status.name}-${profile.status.name}-'
              '${profile.isReady}-$onboardingKey',
            ),
            child: _destination(auth, profile),
          ),
        if (_splashVisible)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: showApp ? 0 : 1,
              duration: _fadeDuration,
              curve: Curves.easeOut,
              onEnd: () {
                if (!showApp || !_splashVisible || !mounted) return;
                setState(() => _splashVisible = false);
              },
              child: _splash,
            ),
          ),
      ],
    );
  }
}
