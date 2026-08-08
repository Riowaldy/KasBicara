import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi KasBicara: display serif (judul, angka saldo) + sans body (teks umum).
///
/// TODO(fase-6): ganti fontFamily generic ('serif'/default) dengan font kustom
/// (mis. via google_fonts atau asset .ttf) sesuai eksplorasi desain final.
abstract final class AppTypography {
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'serif',
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: 'serif',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'serif',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}
