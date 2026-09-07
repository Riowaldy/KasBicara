import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_assets.dart';
import 'package:kasbicara/data/models/asset_model.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

import '../fakes/fake_asset_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeAssetRepository assets;

  setUp(() => assets = FakeAssetRepository(defaultAssets));
  tearDown(() => assets.dispose());

  Asset build(String id, {int sortOrder = 1, String name = 'Aset'}) => Asset(
    id: id,
    name: name,
    icon: 'bank',
    isDefault: false,
    sortOrder: sortOrder,
  );

  test('getAll terurut sort_order lalu nama', () async {
    await assets.create(build('b', sortOrder: 2, name: 'Beta'));
    await assets.create(build('a', sortOrder: 1, name: 'Alfa'));

    final all = await assets.getAll();
    expect(all.map((a) => a.id).toList(), [kMainAssetId, 'a', 'b']);
  });

  test('Aset Utama tidak dapat dihapus', () async {
    expect(() => assets.delete(kMainAssetId), throwsArgumentError);
  });

  test('create menolak nama kosong', () async {
    expect(() => assets.create(build('x', name: '  ')), throwsArgumentError);
  });

  test('watchAll memancarkan ulang setiap perubahan', () async {
    final counts = <int>[];
    final sub = assets.watchAll().listen((list) => counts.add(list.length));

    await Future<void>.delayed(Duration.zero);
    await assets.create(build('a2'));
    await Future<void>.delayed(Duration.zero);
    await assets.delete('a2');
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(counts, [1, 2, 1]);
  });

  test(
    'hapus aset berisi transaksi: reassign ke Aset Utama lalu delete',
    () async {
      final tx = FakeTransactionRepository();
      addTearDown(tx.dispose);
      await assets.create(build('bank-bca', name: 'Bank BCA'));

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
          assetId: 'bank-bca',
        ),
      );

      await tx.reassignAsset(fromAssetId: 'bank-bca', toAssetId: kMainAssetId);
      await assets.delete('bank-bca');

      final all = await tx.getAll();
      expect(all.single.assetId, kMainAssetId);
      expect((await assets.getAll()).map((a) => a.id), [kMainAssetId]);
    },
  );
}
