import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Palet kategorikal untuk grafik donat (Dashboard §6.5) — 8 hue, urutan
/// tetap, divalidasi (skill dataviz) terhadap `AppColors.inkSurface`
/// (#122B52): lolos band lightness/chroma, pemisahan CVD (worst adjacent
/// ΔE 8.4), dan lantai normal-vision (worst adjacent ΔE 19.3). Satu slot
/// (hijau, indeks 5) di bawah kontras 3:1 terhadap surface — karena itu
/// legend SELALU menampilkan label teks, bukan mengandalkan warna saja
/// ("relief rule").
const _categoricalPaletteDark = <Color>[
  Color(0xFF3987E5), // 1 biru
  Color(0xFFD95926), // 2 oranye
  Color(0xFF199E70), // 3 aqua
  Color(0xFFC98500), // 4 kuning
  Color(0xFFD55181), // 5 magenta
  Color(0xFF008300), // 6 hijau
  Color(0xFF9085E9), // 7 violet
  Color(0xFFE66767), // 8 merah
];

/// Urutan tetap kategori pengeluaran default — warna mengikuti ENTITAS
/// (posisi kategori ini), bukan urutan/rank di grafik (yang bisa berubah
/// tiap periode). Kategori kustom (Fase 1.1) jatuh ke [AppColors.textMuted].
const _categoryColorOrder = <String>[
  'expense-makanan-minuman',
  'expense-transportasi',
  'expense-belanja',
  'expense-tagihan-utilitas',
  'expense-kesehatan',
  'expense-hiburan',
  'expense-pendidikan',
  'expense-lainnya',
];

Color colorForCategory(String categoryId) {
  final index = _categoryColorOrder.indexOf(categoryId);
  if (index == -1) return AppColors.textMuted;
  return _categoricalPaletteDark[index];
}
