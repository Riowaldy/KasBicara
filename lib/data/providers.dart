import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import '../core/utils/date_utils.dart';
import 'datasources/app_database.dart';
import 'models/category_model.dart';
import 'models/transaction_model.dart';
import 'models/transaction_type.dart';
import 'repositories/category_repository.dart';
import 'repositories/transaction_repository.dart';

/// Koneksi database terenkripsi (dibuka sekali, di-cache oleh [AppDatabase]).
final databaseProvider = FutureProvider<Database>((ref) async {
  return AppDatabase.instance.database;
});

/// Repository transaksi.
final transactionRepositoryProvider = FutureProvider<TransactionRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SqfliteTransactionRepository(db);
});

/// Repository kategori.
final categoryRepositoryProvider = FutureProvider<CategoryRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SqfliteCategoryRepository(db);
});

/// Seluruh transaksi, reaktif — otomatis terupdate setiap ada
/// create/update/delete (FR-6). Dikonsumsi Beranda, Riwayat, & Dashboard.
final transactionsStreamProvider = StreamProvider<List<Transaction>>((
  ref,
) async* {
  final repo = await ref.watch(transactionRepositoryProvider.future);
  yield* repo.watchAll();
});

/// Saldo total (akumulasi semua transaksi) — PRD §6.5.
final balanceProvider = Provider<AsyncValue<int>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.whenData(
    (list) => list.fold<int>(
      0,
      (sum, t) =>
          sum + (t.type == TransactionType.masuk ? t.amount : -t.amount),
    ),
  );
});

/// Seluruh kategori (default + kustom).
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = await ref.watch(categoryRepositoryProvider.future);
  return repo.getAll();
});

/// Kategori tersaring berdasarkan jenis transaksi (untuk dropdown form).
final categoriesByTypeProvider =
    FutureProvider.family<List<Category>, TransactionType>((ref, type) async {
      final repo = await ref.watch(categoryRepositoryProvider.future);
      return repo.getByType(type);
    });

/// Daftar bulan (`YYYY-MM`) yang benar-benar punya transaksi, terbaru dulu
/// — dipakai mengisi opsi dropdown filter bulan (Riwayat & Dashboard).
final availableMonthsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.whenData((list) {
    final months = list.map((t) => toMonthKey(t.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  });
});
