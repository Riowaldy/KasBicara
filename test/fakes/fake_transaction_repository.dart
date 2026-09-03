import 'dart:async';

import 'package:kasbicara/core/utils/date_utils.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/repositories/transaction_repository.dart';

/// Implementasi in-memory [TransactionRepository] untuk pengujian.
///
/// Mereplikasi semantik filter (`monthKey`, `category`) dan urutan hasil
/// yang sama seperti [SqfliteTransactionRepository], tanpa bergantung pada
/// platform channel — sehingga bisa dijalankan di `flutter test` biasa.
class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _items = [];
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> create(Transaction transaction) async {
    transaction.validate();
    if (_items.any((t) => t.id == transaction.id)) {
      throw StateError('Transaksi dengan id ${transaction.id} sudah ada');
    }
    _items.add(transaction);
    _notify();
  }

  @override
  Future<void> update(Transaction transaction) async {
    transaction.validate();
    final index = _items.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      throw StateError('Transaksi ${transaction.id} tidak ditemukan');
    }
    _items[index] = transaction;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((t) => t.id == id);
    _notify();
  }

  @override
  Future<void> reassignPocket({
    required String fromPocketId,
    required String toPocketId,
  }) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].pocketId == fromPocketId) {
        _items[i] = _items[i].copyWith(pocketId: toPocketId);
      }
    }
    _notify();
  }

  @override
  Future<Transaction?> getById(String id) async {
    for (final t in _items) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<List<Transaction>> getAll() async {
    final sorted = [..._items];
    sorted.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  @override
  Future<List<Transaction>> getFiltered({
    String? monthKey,
    String? category,
  }) async {
    final all = await getAll();
    return all.where((t) {
      if (monthKey != null && toMonthKey(t.date) != monthKey) return false;
      if (category != null && t.category != category) return false;
      return true;
    }).toList();
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
