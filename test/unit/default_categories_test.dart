import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_categories.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

void main() {
  test('semua ID kategori default unik', () {
    final ids = defaultCategories.map((c) => c.id).toSet();
    expect(ids.length, defaultCategories.length);
  });

  test('semua kategori default valid (nama tidak kosong)', () {
    for (final category in defaultCategories) {
      expect(() => category.validate(), returnsNormally);
      expect(category.isDefault, isTrue);
    }
  });

  test('8 kategori pengeluaran & 5 kategori pemasukan sesuai PRD §6.4', () {
    final expense = defaultCategories.where(
      (c) => c.type == TransactionType.keluar,
    );
    final income = defaultCategories.where(
      (c) => c.type == TransactionType.masuk,
    );

    expect(expense.length, 8);
    expect(income.length, 5);
  });
}
