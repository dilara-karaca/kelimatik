import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

/// Typography with full Turkish coverage (ş, ı, ğ, ü, ö, ç, İ).
abstract final class AppTypography {
  static const List<String> _turkishFallback = [
    'Noto Sans',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static TextStyle brand({
    Color color = AppColors.textPrimary,
    double fontSize = 28,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  static TextStyle title({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textSecondary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  static TextStyle score({
    required Color color,
    double fontSize = 24,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.1,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }

  static TextStyle word({
    required Color color,
    double fontSize = 34,
  }) {
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.2,
      height: 1.2,
    ).copyWith(fontFamilyFallback: _turkishFallback);
  }
}
