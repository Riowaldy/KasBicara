import 'dart:async';

import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import '../models/transaction_model.dart';

/// Kontrak akses data transaksi — diimplementasikan oleh
/// [SqfliteTransactionRepository] (produksi). Abstraksi ini memungkinkan
/// fitur di layer atas (mis. dashboard, riwayat) diuji tanpa database nyata.
abstract class TransactionRepository {
  Future<void> create(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<void> delete(String id);
  Future<Transaction?> getById(String id);
  Future<List<Transaction>> getAll();

  /// [monthKey] berformat `YYYY-MM` (lihat `core/utils/date_utils.dart`).
  Future<List<Transaction>> getFiltered({String? monthKey, String? category});

  /// Pindahkan semua transaksi dari satu pocket ke pocket lain — dipakai
  /// sebelum menghapus pocket (konsep "Pocket KasBicara" §06). Memancarkan
  /// perubahan ke [watchAll] agar UI ikut ter‑refresh.
  Future<void> reassignPocket({
    required String fromPocketId,
    required String toPocketId,
  });

  /// Stream reaktif — memancarkan ulang daftar transaksi setiap ada
  /// create/update/delete. Dipakai dashboard (Fase 4) agar auto-update (FR-6).
  Stream<List<Transaction>> watchAll();

  Future<void> dispose();
}

class SqfliteTransactionRepository implements TransactionRepository {
  SqfliteTransactionRepository(this._db);

  static const _table = 'transactions';

  final Database _db;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> create(Transaction transaction) async {
    transaction.validate();
    await _db.insert(_table, transaction.toMap());
    _notify();
  }

  @override
  Future<void> update(Transaction transaction) async {
    transaction.validate();
    await _db.update(
      _table,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  @override
  Future<void> reassignPocket({
    required String fromPocketId,
    required String toPocketId,
  }) async {
    await _db.update(
      _table,
      {'pocket_id': toPocketId},
      where: 'pocket_id = ?',
      whereArgs: [fromPocketId],
    );
    _notify();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Transaction.fromMap(rows.first);
  }

  @override
  Future<List<Transaction>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'date DESC, created_at DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  @override
  Future<List<Transaction>> getFiltered({
    String? monthKey,
    String? category,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];

    if (monthKey != null) {
      conditions.add('date LIKE ?');
      args.add('$monthKey%');
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }

    final rows = await _db.query(
      _table,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  @override
  Stream<List<Transaction>> watchAll() async* {
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
