import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/study_mode.dart';
import '../navigation/soft_transitions.dart';
import '../navigation/study_navigation.dart';
import 'motion/motion.dart';

Future<void> showChallengePresetsSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showSoftModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ChallengePresetsSheet(
        onSelect: (package) async {
          Navigator.of(sheetContext).pop();
          await openStudySession(context, ref, package.toConfig());
        },
      );
    },
  );
}

class _ChallengePresetsSheet extends StatelessWidget {
  const _ChallengePresetsSheet({required this.onSelect});

  final ValueChanged<ChallengePackage> onSelect;

  @override
  Widget build(BuildContext context) {
    final packages = ChallengePresets.packages;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Challenge', style: AppTypography.brand(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                'Hazır bir paket seç, hemen başla.',
                style: AppTypography.title(fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < packages.length; i++) ...[
                FadeSlideIn(
                  delay: AppConstants.entranceStagger * i,
                  child: _PackageButton(
                    package: packages[i],
                    onTap: () => onSelect(packages[i]),
                  ),
                ),
                if (i < packages.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageButton extends StatelessWidget {
  const _PackageButton({
    required this.package,
    required this.onTap,
  });

  final ChallengePackage package;
  final VoidCallback onTap;

  String get _badge {
    if (package.timeLimit != null) {
      return '${package.timeLimit!.inMinutes} dk';
    }
    return '${package.targetCount} kelime';
  }

  String get _blurb {
    final parts = package.subtitle.split('—');
    if (parts.length > 1) return parts.last.trim();
    return package.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      child: Material(
        color: AppColors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.accent.withValues(alpha: 0.10),
          highlightColor: AppColors.accent.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6E8EC)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                package.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _badge,
                                style: AppTypography.title(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _blurb,
                          style: AppTypography.title(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
