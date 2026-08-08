import 'package:flutter/material.dart';

/// Palet warna KasBicara — mengikuti visual identity prototipe:
/// dasar "ink" hijau gelap, aksen emas, income hijau, expense terracotta.
abstract final class AppColors {
  // Ink (dasar gelap, konsep "buku kas")
  static const Color inkBackground = Color(0xFF0E241B);
  static const Color inkSurface = Color(0xFF16352A);
  static const Color inkSurfaceAlt = Color(0xFF1D4433);
  static const Color inkBorder = Color(0xFF2C5A45);

  // Aksen emas
  static const Color gold = Color(0xFFD8AE5C);
  static const Color goldMuted = Color(0xFFB8903F);

  // Semantik transaksi
  static const Color income = Color(0xFF4C9A6B);
  static const Color expense = Color(0xFFC1573B);

  // Teks di atas dasar gelap
  static const Color textPrimary = Color(0xFFF5F1E6);
  static const Color textMuted = Color(0xFFA8B8AE);

  // Status
  static const Color error = Color(0xFFE0563A);
}
