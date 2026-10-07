import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/streak_reward_cycle.dart';

class RollingStreakNumber extends StatelessWidget {
  const RollingStreakNumber({
    super.key,
    required this.from,
    required this.to,
    required this.progress,
  });

  final int from;
  final int to;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final pairs = rollingDigitPairs(from, to);
    final style = AppTypography.brand(
      fontSize: 72,
      color: AppColors.primary,
    ).copyWith(
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: -2,
    );

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final pair in pairs)
              _RollingDigit(
                from: pair.from,
                to: pair.to,
                t: progress.value.clamp(0.0, 1.0),
                style: style,
              ),
          ],
        );
      },
    );
  }
}

class _RollingDigit extends StatelessWidget {
  const _RollingDigit({
    required this.from,
    required this.to,
    required this.t,
    required this.style,
  });

  final String from;
  final String to;
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: '8', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    final height = painter.height;

    if (from == to) {
      return SizedBox(
        width: width,
        height: height,
        child: Text(to, style: style, textAlign: TextAlign.center),
      );
    }

    final curve = Curves.easeInOutCubic.transform(t);
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            if (from.trim().isNotEmpty)
              Transform.translate(
                offset: Offset(0, -height * curve),
                child: Text(from, style: style, textAlign: TextAlign.center),
              ),
            Transform.translate(
              offset: Offset(0, height * (1 - curve)),
              child: Text(to, style: style, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
