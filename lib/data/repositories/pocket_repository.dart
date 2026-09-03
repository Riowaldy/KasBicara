import 'dart:async';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/pocket_model.dart';

/// Kontrak akses data pocket (konsep "Pocket KasBicara" §05).
///
/// Pocket Utama sudah di‑seed saat database dibuat/di‑upgrade — lihat
/// `AppDatabase` (`onCreate` / `onUpgrade`). Integritas relasi transaksi↔
/// pocket dijaga di layer aplikasi: hapus pocket harus didahului
/// `TransactionRepository.reassignPocket`.
abstract class PocketRepository {
  Future<void> create(Pocket pocket);
  Future<void> update(Pocket pocket);
  Future<void> delete(String id);
  Future<List<Pocket>> getAll();

  /// Stream reaktif — memancarkan ulang daftar pocket setiap ada
  /// create/update/delete, agar selector & dropdown form auto‑update.
  Stream<List<Pocket>> watchAll();

  Future<void> dispose();
}

class SqflitePocketRepository implements PocketRepository {
  SqflitePocketRepository(this._db);

  static const _table = 'pockets';

  final Database _db;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> create(Pocket pocket) async {
    pocket.validate();
    await _db.insert(_table, pocket.toMap());
    _notify();
  }

  @override
  Future<void> update(Pocket pocket) async {
    pocket.validate();
    await _db.update(
      _table,
      pocket.toMap(),
      where: 'id = ?',
      whereArgs: [pocket.id],
    );
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    // Pocket Utama tidak boleh dihapus (konsep §02) — pertahanan di data
    // layer, UI juga menyembunyikan aksinya.
    if (id == kMainPocketId) {
      throw ArgumentError.value(id, 'id', 'Pocket Utama tidak dapat dihapus');
    }
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  @override
  Future<List<Pocket>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'sort_order ASC, name ASC');
    return rows.map(Pocket.fromMap).toList();
  }

  @override
  Stream<List<Pocket>> watchAll() async* {
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
