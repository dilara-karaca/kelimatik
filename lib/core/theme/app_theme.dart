import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      primary: AppColors.accent,
      secondary: AppColors.sky,
      tertiary: AppColors.mint,
      surface: AppColors.surfaceElevated,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundTop,
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
