import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/asset_model.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';
import 'package:kasbicara/data/providers.dart';
import 'package:kasbicara/features/history/application/history_providers.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Transaction tx({
    required String id,
    required DateTime date,
    TransactionType type = TransactionType.keluar,
    String category = 'expense-lainnya',
    String assetId = kMainAssetId,
    String pocketId = 'pocket_main',
  }) {
    return Transaction(
      id: id,
      type: type,
      amount: 10000,
      category: category,
      date: date,
      createdAt: date,
      updatedAt: date,
      assetId: assetId,
      pocketId: pocketId,
    );
  }

  Future<ProviderContainer> containerWith(List<Transaction> seed) async {
    final repo = FakeTransactionRepository();
    for (final t in seed) {
      await repo.create(t);
    }
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repo.dispose);
    await container.read(transactionsStreamProvider.future);
    return container;
  }

  List<String> ids(ProviderContainer c) =>
      (c.read(filteredTransactionsProvider).value ?? [])
          .map((t) => t.id)
          .toList();

  test('default monthly hanya memuat transaksi bulan berjalan', () async {
    final c = await containerWith([
      tx(id: 'this-month', date: DateTime(now.year, now.month, 1)),
      tx(id: 'last-month', date: DateTime(now.year, now.month - 1, 15)),
    ]);
    expect(c.read(historyPeriodFilterProvider), HistoryPeriod.monthly);
    expect(ids(c), ['this-month']);
  });

  test('daily hanya hari ini; all memuat semuanya', () async {
    final c = await containerWith([
      tx(id: 'today', date: today),
      tx(id: 'yesterday', date: today.subtract(const Duration(days: 1))),
      tx(id: 'old', date: DateTime(now.year - 2, 1, 1)),
    ]);

    c.read(historyPeriodFilterProvider.notifier).state = HistoryPeriod.daily;
    expect(ids(c), ['today']);

    c.read(historyPeriodFilterProvider.notifier).state = HistoryPeriod.all;
    expect(ids(c)..sort(), ['old', 'today', 'yesterday']);
  });

  test('weekly memuat rentang Senin..Minggu memuat hari ini', () async {
    final c = await containerWith([tx(id: 'today', date: today)]);
    c.read(historyPeriodFilterProvider.notifier).state = HistoryPeriod.weekly;
    expect(ids(c), ['today']);
  });

  test('filter tipe, aset, kategori, pocket digabung dengan AND', () async {
    final c = await containerWith([
      tx(
        id: 'keep',
        date: today,
        type: TransactionType.masuk,
        category: 'income-gaji',
        assetId: 'bank',
        pocketId: 'p2',
      ),
      tx(
        id: 'wrong-type',
        date: today,
        type: TransactionType.keluar,
        category: 'income-gaji',
        assetId: 'bank',
        pocketId: 'p2',
      ),
      tx(
        id: 'wrong-asset',
        date: today,
        type: TransactionType.masuk,
        category: 'income-gaji',
        assetId: 'cash',
        pocketId: 'p2',
      ),
      tx(
        id: 'wrong-cat',
        date: today,
        type: TransactionType.masuk,
        category: 'income-bonus',
        assetId: 'bank',
        pocketId: 'p2',
      ),
      tx(
        id: 'wrong-pocket',
        date: today,
        type: TransactionType.masuk,
        category: 'income-gaji',
        assetId: 'bank',
        pocketId: 'p9',
      ),
    ]);

    c.read(historyPeriodFilterProvider.notifier).state = HistoryPeriod.all;
    c.read(historyTypeFilterProvider.notifier).state = TransactionType.masuk;
    c.read(historyAssetFilterProvider.notifier).state = 'bank';
    c.read(historyCategoryFilterProvider.notifier).state = 'income-gaji';
    c.read(activePocketProvider.notifier).state = 'p2';

    expect(ids(c), ['keep']);
  });
}
