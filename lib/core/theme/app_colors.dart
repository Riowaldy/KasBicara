import 'package:flutter/material.dart';

/// Palet warna KasBicara — mengikuti logo resmi aplikasi:
/// dasar "ink" navy biru gelap, aksen emas, income hijau, expense terracotta.
///
/// Nama field ("ink...") dipertahankan dari revisi hijau sebelumnya agar
/// tidak mengubah API di seluruh codebase — hanya nilai warnanya yang diganti.
abstract final class AppColors {
  // Ink (dasar gelap, konsep "buku kas") — navy sesuai logo
  static const Color inkBackground = Color(0xFF0B1E3D);
  static const Color inkSurface = Color(0xFF122B52);
  static const Color inkSurfaceAlt = Color(0xFF1A3A6B);
  static const Color inkBorder = Color(0xFF2C4C7C);

  // Aksen emas
  static const Color gold = Color(0xFFE3B463);
  static const Color goldMuted = Color(0xFFC79A4E);

  // Semantik transaksi
  static const Color income = Color(0xFF4C9A6B);
  static const Color expense = Color(0xFFC1573B);

  // Teks di atas dasar gelap
  static const Color textPrimary = Color(0xFFF7F1E4);
  static const Color textMuted = Color(0xFF9FB0C9);

  // Status
  static const Color error = Color(0xFFE0563A);
}
