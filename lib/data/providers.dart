import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import 'datasources/app_database.dart';
import 'repositories/category_repository.dart';
import 'repositories/transaction_repository.dart';

/// Koneksi database terenkripsi (dibuka sekali, di-cache oleh [AppDatabase]).
final databaseProvider = FutureProvider<Database>((ref) async {
  return AppDatabase.instance.database;
});

/// Repository transaksi — dikonsumsi UI mulai Fase 2.
final transactionRepositoryProvider = FutureProvider<TransactionRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SqfliteTransactionRepository(db);
});

/// Repository kategori — dikonsumsi UI mulai Fase 2.
final categoryRepositoryProvider = FutureProvider<CategoryRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SqfliteCategoryRepository(db);
});
