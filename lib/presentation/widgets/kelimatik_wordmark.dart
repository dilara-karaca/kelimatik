import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';

/// Two-tone KELİMATİK wordmark (logo font, not Poppins).
///
/// KELİ → [AppColors.dark] · MATİK → [AppColors.secondary]
class KelimatikWordmark extends StatelessWidget {
  const KelimatikWordmark({
    super.key,
    this.fontSize = 26,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.logo(fontSize: fontSize);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: 'KELİ',
            style: base.copyWith(color: AppColors.dark),
          ),
          TextSpan(
            text: 'MATİK',
            style: base.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
