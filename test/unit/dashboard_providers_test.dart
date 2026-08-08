import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/utils/date_utils.dart';
import 'package:kasbicara/data/datasources/default_categories.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';
import 'package:kasbicara/data/providers.dart';
import 'package:kasbicara/features/dashboard/application/dashboard_providers.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository txRepo;
  late ProviderContainer container;

  setUp(() {
    txRepo = FakeTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) async => txRepo),
        categoryRepositoryProvider.overrideWith(
          (ref) async => FakeCategoryRepository(defaultCategories),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Transaction build({
    required String id,
    required DateTime date,
    required TransactionType type,
    required int amount,
    String category = 'expense-makanan-minuman',
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

  test(
    'periodSummaryProvider menjumlahkan income/expense sesuai periode terpilih',
    () async {
      await txRepo.create(
        build(
          id: 't1',
          date: DateTime(2026, 8, 5),
          type: TransactionType.masuk,
          amount: 1000000,
        ),
      );
      await txRepo.create(
        build(
          id: 't2',
          date: DateTime(2026, 8, 10),
          type: TransactionType.keluar,
          amount: 200000,
        ),
      );
      await txRepo.create(
        // beda bulan, harus diabaikan
        build(
          id: 't3',
          date: DateTime(2026, 7, 1),
          type: TransactionType.keluar,
          amount: 999999,
        ),
      );

      await container.read(transactionsStreamProvider.future);
      container.read(dashboardPeriodProvider.notifier).state = '2026-08';

      final summary = container.read(periodSummaryProvider).value!;
      expect(summary.income, 1000000);
      expect(summary.expense, 200000);
      expect(summary.balance, 800000);
    },
  );

  test(
    'categoryBreakdownProvider hanya menghitung pengeluaran periode terpilih, terurut terbesar',
    () async {
      await txRepo.create(
        build(
          id: 't1',
          date: DateTime(2026, 8, 1),
          type: TransactionType.keluar,
          amount: 50000,
          category: 'expense-makanan-minuman',
        ),
      );
      await txRepo.create(
        build(
          id: 't2',
          date: DateTime(2026, 8, 2),
          type: TransactionType.keluar,
          amount: 150000,
          category: 'expense-transportasi',
        ),
      );
      await txRepo.create(
        // pemasukan, harus diabaikan dari grafik pengeluaran
        build(
          id: 't3',
          date: DateTime(2026, 8, 3),
          type: TransactionType.masuk,
          amount: 999999,
        ),
      );

      await container.read(transactionsStreamProvider.future);
      await container.read(categoriesProvider.future);
      container.read(dashboardPeriodProvider.notifier).state = '2026-08';

      final slices = container.read(categoryBreakdownProvider).value!;
      expect(slices.length, 2);
      expect(slices.first.categoryId, 'expense-transportasi');
      expect(slices.first.amount, 150000);
      expect(slices.first.percentage, closeTo(0.75, 0.001));
      expect(slices.last.categoryId, 'expense-makanan-minuman');
    },
  );

  test(
    'sixMonthTrendProvider mengisi 6 bulan berturut, termasuk bulan tanpa data',
    () async {
      final now = DateTime.now();
      await txRepo.create(
        build(id: 't1', date: now, type: TransactionType.masuk, amount: 500000),
      );

      await container.read(transactionsStreamProvider.future);

      final months = container.read(sixMonthTrendProvider).value!;
      expect(months.length, 6);
      expect(months.last.monthKey, toMonthKey(now));
      expect(months.last.income, 500000);
      expect(months.first.income, 0);
      expect(months.first.expense, 0);
    },
  );
}
