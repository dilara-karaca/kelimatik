import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import 'app_icon.dart';

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

  /// bos_can fills ~90% of its canvas; dolu_can ~53%. Scale empty down so
  /// both hearts look the same size inside the same slot.
  static const double _emptyVisualScale = 0.58;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(AppConstants.maxLives, (index) {
        final alive = index < current;
        return Padding(
          padding: EdgeInsets.only(
            right: index == AppConstants.maxLives - 1 ? 0 : spacing,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AppIcon(
                alive ? AppIcons.lifeFull : AppIcons.lifeEmpty,
                size: alive ? size : size * _emptyVisualScale,
              ),
            ),
          ),
        );
      }),
    );
  }
}
