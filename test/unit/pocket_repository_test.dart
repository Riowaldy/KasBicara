import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_pockets.dart';
import 'package:kasbicara/data/models/pocket_model.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

import '../fakes/fake_pocket_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakePocketRepository pockets;

  setUp(() => pockets = FakePocketRepository(defaultPockets));
  tearDown(() => pockets.dispose());

  Pocket build(String id, {int sortOrder = 1, String name = 'Pocket'}) =>
      Pocket(
        id: id,
        name: name,
        icon: 'wallet',
        isDefault: false,
        sortOrder: sortOrder,
      );

  test('getAll terurut sort_order lalu nama', () async {
    await pockets.create(build('b', sortOrder: 2, name: 'Beta'));
    await pockets.create(build('a', sortOrder: 1, name: 'Alfa'));

    final all = await pockets.getAll();
    expect(all.map((p) => p.id).toList(), [kMainPocketId, 'a', 'b']);
  });

  test('Pocket Utama tidak dapat dihapus', () async {
    expect(() => pockets.delete(kMainPocketId), throwsArgumentError);
  });

  test('create menolak nama kosong', () async {
    expect(() => pockets.create(build('x', name: '  ')), throwsArgumentError);
  });

  test('watchAll memancarkan ulang setiap perubahan', () async {
    final counts = <int>[];
    final sub = pockets.watchAll().listen((list) => counts.add(list.length));

    await Future<void>.delayed(Duration.zero);
    await pockets.create(build('p2'));
    await Future<void>.delayed(Duration.zero);
    await pockets.delete('p2');
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(counts, [1, 2, 1]);
  });

  test('hapus pocket berisi transaksi: reassign ke Pocket Utama lalu delete '
      '(konsep §06 / FR-P5)', () async {
    final tx = FakeTransactionRepository();
    addTearDown(tx.dispose);
    await pockets.create(build('kas-warung', name: 'Kas Warung'));

    final now = DateTime(2026, 9, 1);
    await tx.create(
      Transaction(
        id: 't1',
        type: TransactionType.masuk,
        amount: 100000,
        category: 'income-lainnya',
        date: now,
        createdAt: now,
        updatedAt: now,
        pocketId: 'kas-warung',
      ),
    );

    await tx.reassignPocket(
      fromPocketId: 'kas-warung',
      toPocketId: kMainPocketId,
    );
    await pockets.delete('kas-warung');

    final all = await tx.getAll();
    expect(all.single.pocketId, kMainPocketId);
    expect((await pockets.getAll()).map((p) => p.id), [kMainPocketId]);
  });
}
