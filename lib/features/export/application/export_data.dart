import 'package:flutter/foundation.dart' hide Category;

import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';

/// Payload siap-ekspor: transaksi yang SUDAH difilter oleh pemanggil
/// (Riwayat/Dashboard) sesuai periode & kategori aktif (PRD §6.7, Flow B).
@immutable
class ExportData {
  const ExportData({
    required this.transactions,
    required this.categoriesById,
    required this.periodLabel,
    this.assetNamesById = const {},
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  /// Nama aset per id — sudah terlokalisasi oleh pemanggil (Aset Utama
  /// dirender dari l10n).
  final Map<String, String> assetNamesById;

  /// Deskripsi filter aktif untuk ditampilkan di laporan, mis. "Agustus
  /// 2026" atau "Agustus 2026 · Makanan & Minuman".
  final String periodLabel;

  String categoryNameFor(Transaction t) =>
      categoriesById[t.category]?.name ?? t.category;

  String assetNameFor(Transaction t) => assetNamesById[t.assetId] ?? t.assetId;

  int get totalIncome => transactions
      .where((t) => t.type == TransactionType.masuk)
      .fold(0, (sum, t) => sum + t.amount);

  int get totalExpense => transactions
      .where((t) => t.type == TransactionType.keluar)
      .fold(0, (sum, t) => sum + t.amount);

  int get balance => totalIncome - totalExpense;
}
