import 'package:flutter/animation.dart';

/// Pure fuse math so the painter and tests share one burn curve.
abstract final class BombFuse {
  static const Curve burnCurve = Curves.easeIn;

  /// 1 = fully intact fuse, 0 = burned to the bomb.
  ///
  /// [linearElapsed] is wall-clock progress over the 5s question timer
  /// (0 at start, 1 at timeout).
  static double remainingFraction(double linearElapsed) {
    final t = linearElapsed.clamp(0.0, 1.0);
    return 1.0 - burnCurve.transform(t);
  }
}
