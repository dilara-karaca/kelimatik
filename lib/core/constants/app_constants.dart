import 'package:flutter/material.dart';

/// Timing and behavior constants for the quiz loop.
abstract final class AppConstants {
  static const Duration correctFeedbackDuration = Duration(milliseconds: 500);
  static const Duration wrongFeedbackDuration = Duration(milliseconds: 1000);
  static const String wordsAssetPath = 'assets/data/words.json';
  static const String statsPrefsKey = 'quiz_stats';
  static const String livesPrefsKey = 'quiz_lives';

  static const int maxLives = 5;
  static const Duration lifeRegenDuration = Duration(minutes: 2);
}

/// Playful but balanced color tokens.
abstract final class AppColors {
  static const Color backgroundTop = Color(0xFFFFF8F1);
  static const Color backgroundMid = Color(0xFFFFF1F4);
  static const Color backgroundBottom = Color(0xFFEEF7FC);

  static const Color accent = Color(0xFFFF8F66);
  static const Color accentDeep = Color(0xFFF0784A);
  static const Color sky = Color(0xFF4CC9F0);
  static const Color mint = Color(0xFF06D6A0);

  static const Color surface = Color(0xFFFFFFF8);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color correct = Color(0xFF06C167);
  static const Color correctSoft = Color(0xFFE0FFF0);
  static const Color correctGlow = Color(0x3306C167);

  static const Color wrong = Color(0xFFFF4D6D);
  static const Color wrongSoft = Color(0xFFFFE5EA);
  static const Color wrongGlow = Color(0x33FF4D6D);

  static const Color textPrimary = Color(0xFF1F1635);
  static const Color textSecondary = Color(0xFF6E6585);

  static const Color progressTrack = Color(0x33FF6B35);
  static const Color shadow = Color(0x141F1635);
  static const Color shadowSoft = Color(0x0A1F1635);
  static const Color cardIdleBorder = Color(0x22FF6B35);
  static const Color divider = Color(0xFFEDE6DF);
}
