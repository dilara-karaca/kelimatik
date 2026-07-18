import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class LivesHearts extends StatelessWidget {
  const LivesHearts({
    super.key,
    required this.current,
    this.size = 28,
    this.spacing = 6,
  });

  final int current;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(AppConstants.maxLives, (index) {
        final alive = index < current;
        return Padding(
          padding: EdgeInsets.only(right: index == AppConstants.maxLives - 1 ? 0 : spacing),
          child: AnimatedScale(
            scale: alive ? 1 : 0.92,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: size,
              color: alive
                  ? AppColors.wrong
                  : AppColors.wrong.withValues(alpha: 0.28),
            ),
          ),
        );
      }),
    );
  }
}
