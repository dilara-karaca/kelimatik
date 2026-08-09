import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// White-first backdrop for the Kelimatik home UI.
class PlayfulBackground extends StatelessWidget {
  const PlayfulBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundTop,
            AppColors.backgroundMid,
            AppColors.backgroundBottom,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}
