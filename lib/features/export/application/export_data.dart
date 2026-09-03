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
    this.pocketNamesById = const {},
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  /// Nama pocket per id — sudah terlokalisasi oleh pemanggil (Pocket Utama
  /// dirender dari l10n). Konsep "Pocket KasBicara" §08.
  final Map<String, String> pocketNamesById;

  /// Deskripsi filter aktif untuk ditampilkan di laporan, mis. "Agustus
  /// 2026" atau "Agustus 2026 · Makanan & Minuman".
  final String periodLabel;

  String categoryNameFor(Transaction t) =>
      categoriesById[t.category]?.name ?? t.category;

  String pocketNameFor(Transaction t) =>
      pocketNamesById[t.pocketId] ?? t.pocketId;

  int get totalIncome => transactions
      .where((t) => t.type == TransactionType.masuk)
      .fold(0, (sum, t) => sum + t.amount);

  int get totalExpense => transactions
      .where((t) => t.type == TransactionType.keluar)
      .fold(0, (sum, t) => sum + t.amount);

  int get balance => totalIncome - totalExpense;
}
