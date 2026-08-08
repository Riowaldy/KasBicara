import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/category_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

void main() {
  const category = Category(
    id: 'expense-belanja',
    name: 'Belanja',
    type: TransactionType.keluar,
    icon: 'shopping',
    isDefault: true,
  );

  test('toMap/fromMap round-trip mempertahankan semua field', () {
    final restored = Category.fromMap(category.toMap());
    expect(restored, category);
  });

  test('is_default disimpan sebagai integer 0/1', () {
    final map = category.toMap();
    expect(map['is_default'], 1);

    final nonDefault = category.copyWith(isDefault: false);
    expect(nonDefault.toMap()['is_default'], 0);
  });

  test('validate menolak nama kosong', () {
    final invalid = category.copyWith(name: '   ');
    expect(() => invalid.validate(), throwsArgumentError);
  });
}
