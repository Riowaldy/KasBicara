import 'package:kasbicara/data/models/category_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';
import 'package:kasbicara/data/repositories/category_repository.dart';

/// Implementasi in-memory [CategoryRepository] untuk pengujian.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([List<Category> seed = const []]) : _items = [...seed];

  final List<Category> _items;

  @override
  Future<void> create(Category category) async {
    category.validate();
    if (_items.any((c) => c.id == category.id)) {
      throw StateError('Kategori dengan id ${category.id} sudah ada');
    }
    _items.add(category);
  }

  @override
  Future<void> update(Category category) async {
    category.validate();
    final index = _items.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      throw StateError('Kategori ${category.id} tidak ditemukan');
    }
    _items[index] = category;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Category>> getAll() async {
    final sorted = [..._items]..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  @override
  Future<List<Category>> getByType(TransactionType type) async {
    final all = await getAll();
    return all.where((c) => c.type == type).toList();
  }
}
