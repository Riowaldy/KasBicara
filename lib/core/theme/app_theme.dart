import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// ThemeData tunggal KasBicara (dasar gelap "buku kas") — bukan tema
/// light/dark yang bisa ditoggle, melainkan identitas visual produk.
abstract final class AppTheme {
  static ThemeData get theme {
    final colorScheme = const ColorScheme.dark().copyWith(
      brightness: Brightness.dark,
      primary: AppColors.gold,
      onPrimary: AppColors.inkBackground,
      secondary: AppColors.income,
      // Navy (bukan cream) di atas secondary/error — cream hanya 3.0:1 di
      // atas income/errorText, di bawah ambang teks WCAG AA 4.5:1.
      onSecondary: AppColors.inkBackground,
      surface: AppColors.inkSurface,
      onSurface: AppColors.textPrimary,
      // errorText (bukan error) — [error] dikhususkan untuk elemen grafis
      // besar (lihat app_colors.dart); teks butuh varian yang lebih terang.
      error: AppColors.errorText,
      onError: AppColors.inkBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.inkBackground,
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.inkBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.inkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.inkBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.inkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.inkBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.inkBackground,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inkBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.inkBorder),
    );
  }
}
