import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

/// Typography system:
/// - [logo] → display / wordmark font (not Poppins)
/// - everything else → Poppins
abstract final class AppTypography {
  static const List<String> _turkishFallback = [
    'Noto Sans',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  /// Brand wordmark only (KELİMATİK). Playful, thick, hand-drawn character.
  static TextStyle logo({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double height = 1.05,
  }) {
    return GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.2,
      height: height,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  /// Section / screen headlines (Poppins Bold).
  static TextStyle brand({
    Color color = AppColors.textPrimary,
    double fontSize = 28,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  /// Secondary titles / captions (Poppins SemiBold by default).
  static TextStyle title({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textSecondary,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  /// Body / labels / buttons (Poppins; weight via [fontWeight]).
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  /// Scores and key numbers (Poppins Bold).
  static TextStyle score({
    required Color color,
    double fontSize = 24,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.1,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  /// Quiz word choices (Poppins Bold).
  static TextStyle word({
    required Color color,
    double fontSize = 34,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.2,
      height: 1.2,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }
}
