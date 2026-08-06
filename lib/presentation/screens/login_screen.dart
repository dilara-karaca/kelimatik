import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/playful_background.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    ref.listen<AppAuthState>(authProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      if (previous?.errorMessage == message) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      ref.read(authProvider.notifier).clearError();
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 52,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kelimatik',
                  style: AppTypography.brand(
                    color: AppColors.accent,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Doğru yazımı öğrenmenin en hızlı yolu',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(fontSize: 14),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: auth.isBusy
                        ? null
                        : () => ref
                            .read(authProvider.notifier)
                            .signInWithGoogle(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor:
                          AppColors.accent.withValues(alpha: 0.45),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: auth.isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'G',
                                  style: AppTypography.body(
                                    color: AppColors.accentDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Google ile devam et',
                                style: AppTypography.body(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
