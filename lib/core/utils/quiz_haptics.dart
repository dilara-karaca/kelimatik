import 'package:flutter/services.dart';

/// Centralized haptic cues for quiz interactions.
abstract final class QuizHaptics {
  /// Toggled from Settings; default on.
  static bool enabled = true;

  static Future<void> correct() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Light phone vibration on wrong answer.
  static Future<void> wrong() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await HapticFeedback.vibrate();
  }
}
