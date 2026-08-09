import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import 'app_icon.dart';

/// Favorite toggle with animated swap: [AppIcons.favorite] ↔ [AppIcons.favorited].
class FavoriteToggleIcon extends StatelessWidget {
  const FavoriteToggleIcon({
    super.key,
    required this.favorited,
    this.size = 24,
  });

  final bool favorited;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: AppConstants.cardSwap,
        switchInCurve: AppConstants.pageCurve,
        switchOutCurve: AppConstants.pageReverseCurve,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppConstants.pageCurve,
            reverseCurve: AppConstants.pageReverseCurve,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
              child: child,
            ),
          );
        },
        child: AppIcon(
          favorited ? AppIcons.favorited : AppIcons.favorite,
          key: ValueKey<bool>(favorited),
          size: size,
        ),
      ),
    );
  }
}
