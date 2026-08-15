import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon.dart';

/// Centered error / offline state with optional retry.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.info,
    this.onRetry,
    this.retryLabel = 'Tekrar Dene',
    this.secondaryLabel,
    this.onSecondary,
  });

  factory AppErrorView.fromError(
    Object? error, {
    Key? key,
    VoidCallback? onRetry,
    String retryLabel = 'Tekrar Dene',
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return AppErrorView(
      key: key,
      info: AppErrorInfo.from(error),
      onRetry: onRetry,
      retryLabel: retryLabel,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    );
  }

  final AppErrorInfo info;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  IconData get _fallbackIcon => switch (info.kind) {
        AppErrorKind.offline => Icons.wifi_off_rounded,
        AppErrorKind.loadFailed => Icons.cloud_off_rounded,
        AppErrorKind.generic => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info.kind == AppErrorKind.offline)
              Icon(
                _fallbackIcon,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.55),
              )
            else
              AppIcon(
                AppIcons.info,
                size: 44,
                opacity: 0.55,
              ),
            const SizedBox(height: 16),
            Text(
              info.title,
              textAlign: TextAlign.center,
              style: AppTypography.brand(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              info.message,
              textAlign: TextAlign.center,
              style: AppTypography.title(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
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
                    retryLabel,
                    style: AppTypography.body(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
            if (onSecondary != null && secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: AppTypography.body(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
