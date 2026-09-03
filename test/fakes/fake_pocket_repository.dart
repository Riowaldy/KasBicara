import 'dart:async';

import 'package:kasbicara/data/models/pocket_model.dart';
import 'package:kasbicara/data/repositories/pocket_repository.dart';

/// Implementasi in-memory [PocketRepository] untuk pengujian.
class FakePocketRepository implements PocketRepository {
  FakePocketRepository([List<Pocket> seed = const []]) : _items = [...seed];

  final List<Pocket> _items;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> create(Pocket pocket) async {
    pocket.validate();
    if (_items.any((p) => p.id == pocket.id)) {
      throw StateError('Pocket dengan id ${pocket.id} sudah ada');
    }
    _items.add(pocket);
    _notify();
  }

  @override
  Future<void> update(Pocket pocket) async {
    pocket.validate();
    final index = _items.indexWhere((p) => p.id == pocket.id);
    if (index == -1) throw StateError('Pocket ${pocket.id} tidak ditemukan');
    _items[index] = pocket;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    if (id == kMainPocketId) {
      throw ArgumentError.value(id, 'id', 'Pocket Utama tidak dapat dihapus');
    }
    _items.removeWhere((p) => p.id == id);
    _notify();
  }

  @override
  Future<List<Pocket>> getAll() async {
    final sorted = [..._items]
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    return sorted;
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
