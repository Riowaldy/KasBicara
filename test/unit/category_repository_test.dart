import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/category_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

import '../fakes/fake_category_repository.dart';

void main() {
  const makanan = Category(
    id: 'expense-makanan-minuman',
    name: 'Makanan & Minuman',
    type: TransactionType.keluar,
    icon: 'food',
    isDefault: true,
  );
  const gaji = Category(
    id: 'income-gaji',
    name: 'Gaji',
    type: TransactionType.masuk,
    icon: 'salary',
    isDefault: true,
  );

  late FakeCategoryRepository repo;

  setUp(() => repo = FakeCategoryRepository([makanan, gaji]));

  test('getAll mengembalikan semua kategori terurut nama', () async {
    final all = await repo.getAll();
    expect(all.map((c) => c.name).toList(), ['Gaji', 'Makanan & Minuman']);
  });

  test('getByType hanya mengembalikan kategori sesuai jenis', () async {
    final expense = await repo.getByType(TransactionType.keluar);
    expect(expense, [makanan]);

    final income = await repo.getByType(TransactionType.masuk);
    expect(income, [gaji]);
  });

  test('create menambah kategori kustom baru', () async {
    const kustom = Category(
      id: 'expense-langganan',
      name: 'Langganan',
      type: TransactionType.keluar,
      icon: 'other',
      isDefault: false,
    );
    await repo.create(kustom);

    final all = await repo.getAll();
    expect(all, contains(kustom));
  });

  test('create menolak nama kosong', () async {
    const invalid = Category(
      id: 'x',
      name: '   ',
      type: TransactionType.keluar,
      icon: 'other',
      isDefault: false,
    );
    expect(() => repo.create(invalid), throwsArgumentError);
  });

  test('delete menghapus kategori', () async {
    await repo.delete('income-gaji');
    final all = await repo.getAll();
    expect(all, isNot(contains(gaji)));
  });
}
