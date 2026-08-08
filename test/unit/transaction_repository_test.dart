import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repo;

  setUp(() => repo = FakeTransactionRepository());
  tearDown(() => repo.dispose());

  Transaction build({
    required String id,
    required DateTime date,
    String category = 'expense-makanan-minuman',
    TransactionType type = TransactionType.keluar,
    int amount = 10000,
  }) {
    return Transaction(
      id: id,
      type: type,
      amount: amount,
      category: category,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('CRUD', () {
    test('create lalu getById mengembalikan transaksi yang sama', () async {
      final t = build(id: 't1', date: DateTime(2026, 8, 8));
      await repo.create(t);

      final found = await repo.getById('t1');
      expect(found, t);
    });

    test('create dengan amount <= 0 ditolak', () async {
      final invalid = build(id: 't1', date: DateTime(2026, 8, 8), amount: 0);
      expect(() => repo.create(invalid), throwsArgumentError);
    });

    test(
      'update mengubah field & tetap bisa ditemukan lewat id yang sama',
      () async {
        final t = build(id: 't1', date: DateTime(2026, 8, 8), amount: 10000);
        await repo.create(t);

        await repo.update(t.copyWith(amount: 25000));

        final found = await repo.getById('t1');
        expect(found?.amount, 25000);
      },
    );

    test('delete menghapus transaksi dari getAll', () async {
      final t = build(id: 't1', date: DateTime(2026, 8, 8));
      await repo.create(t);
      await repo.delete('t1');

      expect(await repo.getAll(), isEmpty);
      expect(await repo.getById('t1'), isNull);
    });

    test('getAll mengurutkan dari tanggal terbaru ke terlama', () async {
      await repo.create(build(id: 'old', date: DateTime(2026, 7, 1)));
      await repo.create(build(id: 'new', date: DateTime(2026, 8, 8)));

      final all = await repo.getAll();
      expect(all.map((t) => t.id).toList(), ['new', 'old']);
    });
  });

  group('Filter (FR-7)', () {
    setUp(() async {
      await repo.create(
        build(
          id: 'agu-makanan',
          date: DateTime(2026, 8, 5),
          category: 'expense-makanan-minuman',
        ),
      );
      await repo.create(
        build(
          id: 'agu-transport',
          date: DateTime(2026, 8, 20),
          category: 'expense-transportasi',
        ),
      );
      await repo.create(
        build(
          id: 'juli-makanan',
          date: DateTime(2026, 7, 15),
          category: 'expense-makanan-minuman',
        ),
      );
    });

    test('filter by monthKey', () async {
      final result = await repo.getFiltered(monthKey: '2026-08');
      expect(result.map((t) => t.id).toSet(), {'agu-makanan', 'agu-transport'});
    });

    test('filter by category', () async {
      final result = await repo.getFiltered(
        category: 'expense-makanan-minuman',
      );
      expect(result.map((t) => t.id).toSet(), {'agu-makanan', 'juli-makanan'});
    });

    test('filter by monthKey + category sekaligus', () async {
      final result = await repo.getFiltered(
        monthKey: '2026-08',
        category: 'expense-makanan-minuman',
      );
      expect(result.map((t) => t.id).toList(), ['agu-makanan']);
    });

    test('tanpa filter mengembalikan semua', () async {
      final result = await repo.getFiltered();
      expect(result.length, 3);
    });
  });

  group('watchAll', () {
    test('memancarkan ulang daftar setiap ada perubahan', () async {
      final emissions = <int>[];
      final sub = repo.watchAll().listen((list) => emissions.add(list.length));

      await Future.delayed(Duration.zero); // izinkan emisi awal (list kosong)
      await repo.create(build(id: 't1', date: DateTime(2026, 8, 8)));
      await Future.delayed(Duration.zero);
      await repo.create(build(id: 't2', date: DateTime(2026, 8, 9)));
      await Future.delayed(Duration.zero);

      await sub.cancel();
      expect(emissions, [0, 1, 2]);
    });
  });
}
