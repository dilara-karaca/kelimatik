import 'package:flutter/services.dart';

/// Centralized haptic cues for quiz interactions.
abstract final class QuizHaptics {
  static Future<void> correct() => HapticFeedback.selectionClick();

  /// Light phone vibration on wrong answer.
  static Future<void> wrong() async {
    await HapticFeedback.lightImpact();
    await HapticFeedback.vibrate();
  }
}
