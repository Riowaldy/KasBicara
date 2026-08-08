import 'package:flutter/material.dart';

/// Pemetaan kunci [Category.icon] (string, tersimpan di DB) ke `IconData`
/// konkret untuk ditampilkan di UI. Kunci baru untuk kategori kustom
/// (Fase 1.1) yang tidak terdaftar di sini akan jatuh ke [Icons.category].
const Map<String, IconData> _categoryIcons = {
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_car_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'bills': Icons.receipt_long_rounded,
  'health': Icons.local_hospital_rounded,
  'entertainment': Icons.movie_rounded,
  'education': Icons.school_rounded,
  'other': Icons.category_rounded,
  'salary': Icons.work_rounded,
  'bonus': Icons.card_giftcard_rounded,
  'investment': Icons.trending_up_rounded,
  'transfer_in': Icons.call_received_rounded,
};

IconData iconForCategoryKey(String key) =>
    _categoryIcons[key] ?? Icons.category_rounded;
