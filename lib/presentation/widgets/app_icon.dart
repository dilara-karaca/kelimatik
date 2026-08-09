import 'package:flutter/material.dart';

/// Renders a custom PNG from [AppIcons] without stretching or blowing layout.
///
/// Always occupies a fixed [size]×[size] box. Asset colors are kept as-is
/// unless [color] is provided. Failed loads never expand the layout.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
    this.opacity = 1,
  });

  final String asset;
  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          color: color,
          colorBlendMode: color != null ? BlendMode.srcIn : null,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
