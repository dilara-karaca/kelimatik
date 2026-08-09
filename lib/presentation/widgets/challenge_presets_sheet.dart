import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/study_mode.dart';
import '../navigation/soft_transitions.dart';
import '../navigation/study_navigation.dart';
import 'app_icon.dart';
import 'motion/motion.dart';

Future<void> showChallengePresetsSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showSoftModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              const SizedBox(height: 16),
              Text('Challenge', style: AppTypography.brand(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                'Hazır bir paket seç, hemen başla.',
                style: AppTypography.title(fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...ChallengePresets.packages.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeSlideIn(
                    delay: AppConstants.entranceStagger * entry.key,
                    child: _PackageTile(
                      package: entry.value,
                      onTap: () => onSelect(entry.value),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.onTap,
  });

  final ChallengePackage package;
  final VoidCallback onTap;

  String _iconFor(String id) {
    return switch (id) {
      'hizli' => AppIcons.challengeMode,
      'standart' => AppIcons.timer,
      'sprint' => AppIcons.timerLive,
      'maraton' => AppIcons.league,
      _ => AppIcons.challengeMode,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: AppIcon(_iconFor(package.id), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.title,
                        style: AppTypography.body(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        package.subtitle,
                        style: AppTypography.title(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
