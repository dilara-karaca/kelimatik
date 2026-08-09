import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Lightweight fade+slide for list rows. Only the first [maxAnimated] indices
/// animate to keep long lists cheap.
class SoftListAppear extends StatelessWidget {
  const SoftListAppear({
    super.key,
    required this.index,
    required this.child,
    this.maxAnimated = 8,
  });

  final int index;
  final Widget child;
  final int maxAnimated;

  @override
  Widget build(BuildContext context) {
    if (index >= maxAnimated) return child;

    final duration = AppConstants.cardSwap +
        AppConstants.entranceStagger * (index.clamp(0, maxAnimated));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: AppConstants.pageCurve,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
