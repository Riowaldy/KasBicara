import 'dart:async';

import 'package:kasbicara/data/models/asset_model.dart';
import 'package:kasbicara/data/repositories/asset_repository.dart';

/// Implementasi in-memory [AssetRepository] untuk pengujian.
class FakeAssetRepository implements AssetRepository {
  FakeAssetRepository([List<Asset> seed = const []]) : _items = [...seed];

  final List<Asset> _items;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> create(Asset asset) async {
    asset.validate();
    if (_items.any((a) => a.id == asset.id)) {
      throw StateError('Aset dengan id ${asset.id} sudah ada');
    }
    _items.add(asset);
    _notify();
  }

  @override
  Future<void> update(Asset asset) async {
    asset.validate();
    final index = _items.indexWhere((a) => a.id == asset.id);
    if (index == -1) throw StateError('Aset ${asset.id} tidak ditemukan');
    _items[index] = asset;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    if (id == kMainAssetId) {
      throw ArgumentError.value(id, 'id', 'Aset Utama tidak dapat dihapus');
    }
    if (_items.any((a) => a.id == id && a.isPrimary)) {
      throw ArgumentError.value(
        id,
        'id',
        'Sumber Aset Utama tidak dapat dihapus',
      );
    }
    _items.removeWhere((a) => a.id == id);
    _notify();
  }

  @override
  Future<void> setPrimary(String id) async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isPrimary: _items[i].id == id);
    }
    _notify();
  }

  @override
  Future<List<Asset>> getAll() async {
    final sorted = [..._items]
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    return sorted;
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
