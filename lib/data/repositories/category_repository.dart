import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/category_model.dart';
import '../models/transaction_type.dart';

/// Kontrak akses data kategori. Kategori default sudah di-seed saat
/// database pertama kali dibuat — lihat `AppDatabase._open` (onCreate).
abstract class CategoryRepository {
  Future<void> create(Category category);
  Future<void> update(Category category);
  Future<void> delete(String id);
  Future<List<Category>> getAll();
  Future<List<Category>> getByType(TransactionType type);
}

class SqfliteCategoryRepository implements CategoryRepository {
  SqfliteCategoryRepository(this._db);

  static const _table = 'categories';

  final Database _db;

  @override
  Future<void> create(Category category) async {
    category.validate();
    await _db.insert(_table, category.toMap());
  }

  @override
  Future<void> update(Category category) async {
    category.validate();
    await _db.update(
      _table,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Category>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<List<Category>> getByType(TransactionType type) async {
    final rows = await _db.query(
      _table,
      where: 'type = ?',
      whereArgs: [type.value],
      orderBy: 'name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }
}
