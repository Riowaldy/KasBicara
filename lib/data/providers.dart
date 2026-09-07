import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import '../core/utils/date_utils.dart';
import 'datasources/app_database.dart';
import 'models/asset_model.dart';
import 'models/category_model.dart';
import 'models/transaction_model.dart';
import 'models/transaction_type.dart';
import 'repositories/asset_repository.dart';
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

/// Repository aset (sumber dana / akun).
final assetRepositoryProvider = FutureProvider<AssetRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final repo = SqfliteAssetRepository(db);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Seluruh transaksi, reaktif — otomatis terupdate setiap ada
/// create/update/delete (FR-6). Dikonsumsi Beranda, Riwayat, & Dashboard.
final transactionsStreamProvider = StreamProvider<List<Transaction>>((
  ref,
) async* {
  final repo = await ref.watch(transactionRepositoryProvider.future);
  yield* repo.watchAll();
});

/// Seluruh aset, reaktif — dikonsumsi selector header, dropdown form, &
/// layar Kelola Aset.
final assetsStreamProvider = StreamProvider<List<Asset>>((ref) async* {
  final repo = await ref.watch(assetRepositoryProvider.future);
  yield* repo.watchAll();
});

/// ID "Sumber Aset Utama" — aset ber‑`isPrimary`, fallback [kMainAssetId] bila
/// stream belum siap atau (anomali) tak ada yang ditandai. Dipakai sebagai
/// fallback nilai awal field aset di form transaksi (saat konteks "Semua
/// Aset") & target reassign saat aset lain dihapus. Sumber kebenaran ada di
/// tabel `assets` — sengaja TANPA StateProvider (berbeda dari
/// `activeAssetProvider` yang menyimpan konteks aktif).
final primaryAssetIdProvider = Provider<String>((ref) {
  final assets = ref.watch(assetsStreamProvider).valueOrNull ?? const [];
  for (final a in assets) {
    if (a.isPrimary) return a.id;
  }
  return kMainAssetId;
});

/// Konteks aset aktif — SUMBER KEBENARAN TUNGGAL (sejajar dengan
/// `activeLanguageProvider`). `null` = "Semua Aset" (agregat). Menyetir Saldo,
/// Riwayat, Dashboard, & nilai awal field aset di form.
final activeAssetProvider = StateProvider<String?>((ref) => null);

/// Saldo — menghormati [activeAssetProvider]: `null` = akumulasi semua
/// transaksi (PRD §6.5), selain itu hanya aset terpilih.
final balanceProvider = Provider<AsyncValue<int>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final activeAsset = ref.watch(activeAssetProvider);
  return txAsync.whenData(
    (list) => list
        .where((t) => activeAsset == null || t.assetId == activeAsset)
        .fold<int>(
          0,
          (sum, t) =>
              sum + (t.type == TransactionType.masuk ? t.amount : -t.amount),
        ),
  );
});

/// Saldo satu aset tertentu — dipakai layar Kelola Aset.
final assetBalanceProvider = Provider.family<AsyncValue<int>, String>((
  ref,
  assetId,
) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.whenData(
    (list) => list
        .where((t) => t.assetId == assetId)
        .fold<int>(
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
