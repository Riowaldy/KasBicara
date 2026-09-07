import 'dart:async';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/asset_model.dart';

/// Kontrak akses data aset.
///
/// Aset Utama sudah di‑seed saat database dibuat/di‑upgrade — lihat
/// `AppDatabase` (`onCreate` / `onUpgrade`). Integritas relasi transaksi↔
/// aset dijaga di layer aplikasi: hapus aset harus didahului
/// `TransactionRepository.reassignAsset`.
abstract class AssetRepository {
  Future<void> create(Asset asset);
  Future<void> update(Asset asset);
  Future<void> delete(String id);
  Future<List<Asset>> getAll();

  /// Tandai satu aset sebagai "Sumber Aset Utama" (`is_primary`). Mencabut
  /// flag dari semua aset lain — tepat satu primary setiap saat.
  Future<void> setPrimary(String id);

  /// Stream reaktif — memancarkan ulang daftar aset setiap ada
  /// create/update/delete, agar filter & dropdown form auto‑update.
  Stream<List<Asset>> watchAll();

  Future<void> dispose();
}

class SqfliteAssetRepository implements AssetRepository {
  SqfliteAssetRepository(this._db);

  static const _table = 'assets';

  final Database _db;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> create(Asset asset) async {
    asset.validate();
    await _db.insert(_table, asset.toMap());
    _notify();
  }

  @override
  Future<void> update(Asset asset) async {
    asset.validate();
    await _db.update(
      _table,
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    // Aset Utama tidak boleh dihapus — pertahanan di data layer, UI juga
    // menyembunyikan aksinya.
    if (id == kMainAssetId) {
      throw ArgumentError.value(id, 'id', 'Aset Utama tidak dapat dihapus');
    }
    // Sumber Aset Utama juga terkunci — pengguna harus menandai aset lain
    // sebagai Utama lebih dulu (UI menyembunyikan tombol hapusnya).
    final rows = await _db.query(
      _table,
      columns: ['is_primary'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty && (rows.first['is_primary'] as int?) == 1) {
      throw ArgumentError.value(
        id,
        'id',
        'Sumber Aset Utama tidak dapat dihapus',
      );
    }
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  @override
  Future<void> setPrimary(String id) async {
    await _db.transaction((txn) async {
      await txn.update(_table, {'is_primary': 0});
      await txn.update(
        _table,
        {'is_primary': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    _notify();
  }

  @override
  Future<List<Asset>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'sort_order ASC, name ASC');
    return rows.map(Asset.fromMap).toList();
  }

  @override
  Stream<List<Asset>> watchAll() async* {
    yield await getAll();
    yield* _changes.stream.asyncMap((_) => getAll());
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Future<void> dispose() async {
    await _changes.close();
  }
}
