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

  /// Page / route transitions — snappy fade + subtle slide (~200–280ms).
  static const Duration pageTransition = Duration(milliseconds: 260);
  static const Duration pageReverseTransition = Duration(milliseconds: 220);
  static const Curve pageCurve = Curves.easeOutCubic;
  static const Curve pageReverseCurve = Curves.easeInCubic;

  static const Duration tabTransition = Duration(milliseconds: 220);

  /// Button press micro-interaction.
  static const Duration pressInDuration = Duration(milliseconds: 90);
  static const Duration pressOutDuration = Duration(milliseconds: 150);
  static const Curve pressInCurve = Curves.easeOut;
  static const Curve pressOutCurve = Curves.easeOutCubic;
  static const double pressScale = 0.97;
  static const double pressOpacity = 0.92;

  /// Overlay panels (result / out-of-lives) and one-shot entrances.
  static const Duration overlayAppear = Duration(milliseconds: 240);
  static const Duration entranceDuration = Duration(milliseconds: 280);
  static const Duration entranceStagger = Duration(milliseconds: 48);

  /// Question / card swap inside quiz.
  static const Duration cardSwap = Duration(milliseconds: 220);
}

/// Kelimatik brand + UI color tokens.
///
/// Brand: white canvas, dark text, orange accents, pastel mode cards.
abstract final class AppColors {
  // —— Brand core ——
  static const Color primary = Color(0xFFFC8B04);
  static const Color secondary = Color(0xFFF97316);
  static const Color dark = Color(0xFF292D36);
  static const Color white = Color(0xFFFFFFFF);

  /// Legacy aliases used across the app (map to brand tokens).
  static const Color accent = primary;
  static const Color accentDeep = secondary;

  // —— Surfaces / backgrounds (white-first) ——
  static const Color backgroundTop = white;
  static const Color backgroundMid = white;
  static const Color backgroundBottom = Color(0xFFF7F8FA);

  static const Color surface = white;
  static const Color surfaceElevated = white;

  // —— Study mode pastel cards (do not replace with orange) ——
  static const Color modeChallenge = Color(0xFFD8F5EB);
  static const Color modeMistakes = Color(0xFFFCE0E6);
  static const Color modeStreak = Color(0xFFFFE8D3);
  static const Color modeInfinite = Color(0xFFDFEDF5);

  // —— Soft utility accents (not brand orange) ——
  static const Color sky = Color(0xFF4CC9F0);
  static const Color mint = Color(0xFF06D6A0);

  // —— Correct / wrong (keep distinct from brand orange) ——
  static const Color correct = Color(0xFF06C167);
  static const Color correctSoft = Color(0xFFE0FFF0);
  static const Color correctGlow = Color(0x3306C167);

  static const Color wrong = Color(0xFFFF4D6D);
  static const Color wrongSoft = Color(0xFFFCE0E6);
  static const Color wrongGlow = Color(0x33FF4D6D);

  // —— Text ——
  static const Color textPrimary = dark;
  /// Secondary copy: dark at reduced opacity feel.
  static const Color textSecondary = Color(0x99292D36);

  // —— Chrome ——
  static const Color progressTrack = Color(0x33FC8B04);
  static const Color shadow = Color(0x14292D36);
  static const Color shadowSoft = Color(0x0A292D36);
  static const Color cardIdleBorder = Color(0x22FC8B04);
  static const Color divider = Color(0xFFE8E9EB);
}
