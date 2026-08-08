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

  // Semantik transaksi — dipakai untuk elemen GRAFIS (ikon, isian bar/pie
  // chart, dot legenda): lolos ambang non-teks WCAG AA 3:1 di atas
  // inkBackground/inkSurface, tapi TIDAK cukup untuk teks biasa (4.5:1).
  static const Color income = Color(0xFF4C9A6B);
  static const Color expense = Color(0xFFC1573B);

  // Varian "aman-teks" — versi income/expense yang sedikit lebih terang,
  // lolos kontras teks WCAG AA 4.5:1 di atas inkBackground & inkSurface.
  // Pakai ini untuk TEKS (nominal transaksi, dsb), bukan [income]/[expense].
  static const Color incomeText = Color(0xFF51A472);
  static const Color expenseText = Color(0xFFD17E68);

  // Teks di atas dasar gelap
  static const Color textPrimary = Color(0xFFF7F1E4);
  static const Color textMuted = Color(0xFF9FB0C9);

  // Status — [error] untuk elemen grafis besar (mis. latar swipe-hapus
  // dengan ikon putih di atasnya); [errorText] untuk teks (pesan validasi
  // form via ColorScheme.error) agar tetap lolos kontras AA 4.5:1 di atas
  // inkSurfaceAlt (fill TextField).
  static const Color error = Color(0xFFE0563A);
  static const Color errorText = Color(0xFFEA8B78);
}
