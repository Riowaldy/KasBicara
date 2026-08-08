import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/datasources/default_categories.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/providers.dart';
import 'package:kasbicara/features/dashboard/application/dashboard_providers.dart';
import 'package:kasbicara/features/history/application/history_providers.dart';
import 'package:kasbicara/features/history/application/transaction_grouping.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_transaction_repository.dart';

/// Verifikasi skalabilitas ±10.000 transaksi (NFR PRD §8: "Aplikasi tetap
/// responsif hingga ±10.000 transaksi tersimpan per pengguna").
///
/// Ini membuktikan logika (filter, grouping, agregasi dashboard) tetap
/// murah secara komputasi di skala tersebut — bukan pengukuran render
/// on-device sungguhan (perlu emulator/device fisik, lihat Fase 7 QA).
void main() {
  const transactionCount = 10000;
  // Generous margin di atas ekspektasi nyata (operasi List O(n) murni Dart
  // atas 10rb entri semestinya <50ms) — cukup ketat untuk menangkap regresi
  // tak sengaja jadi O(n²), cukup longgar untuk mesin CI yang lambat.
  const budget = Duration(milliseconds: 1500);

  List<Transaction> generateTransactions(int count) {
    final categories = defaultCategories;
    return List.generate(count, (i) {
      final category = categories[i % categories.length];
      final date = DateTime(2024, 1, 1).add(Duration(days: i % 900));
      return Transaction(
        id: 't$i',
        type: category.type,
        amount: 1000 + (i % 500) * 1000,
        category: category.id,
        note: i % 7 == 0 ? 'Catatan #$i' : null,
        date: date,
        createdAt: date,
        updatedAt: date,
      );
    });
  }

  late FakeTransactionRepository txRepo;
  late List<Transaction> synthetic;

  setUp(() async {
    txRepo = FakeTransactionRepository();
    synthetic = generateTransactions(transactionCount);
    for (final t in synthetic) {
      await txRepo.create(t);
    }
  });

  test(
    'getAll & getFiltered tetap cepat di $transactionCount transaksi',
    () async {
      final stopwatch = Stopwatch()..start();
      final all = await txRepo.getAll();
      final filtered = await txRepo.getFiltered(monthKey: '2024-06');
      stopwatch.stop();

      expect(all.length, transactionCount);
      expect(filtered, isNotEmpty);
      expect(
        stopwatch.elapsed,
        lessThan(budget),
        reason:
            'getAll+getFiltered atas $transactionCount transaksi terlalu lambat',
      );
    },
  );

  test('groupTransactionsForList (Riwayat) tetap cepat', () async {
    final all = await txRepo.getAll();

    final stopwatch = Stopwatch()..start();
    final grouped = groupTransactionsForList(all);
    stopwatch.stop();

    // Setiap transaksi minimal 1 entri + minimal 1 header tanggal.
    expect(grouped.length, greaterThanOrEqualTo(transactionCount));
    expect(
      stopwatch.elapsed,
      lessThan(budget),
      reason:
          'Grouping Riwayat atas $transactionCount transaksi terlalu lambat',
    );
  });

  test(
    'provider Dashboard (ringkasan, breakdown, tren 6 bulan) tetap cepat',
    () async {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) async => txRepo),
          categoryRepositoryProvider.overrideWith(
            (ref) async => FakeCategoryRepository(defaultCategories),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(transactionsStreamProvider.future);
      await container.read(categoriesProvider.future);
      container.read(dashboardPeriodProvider.notifier).state = '2024-06';

      final stopwatch = Stopwatch()..start();
      final summary = container.read(periodSummaryProvider).value;
      final breakdown = container.read(categoryBreakdownProvider).value;
      final trend = container.read(sixMonthTrendProvider).value;
      stopwatch.stop();

      expect(summary, isNotNull);
      expect(breakdown, isNotNull);
      expect(trend, isNotNull);
      expect(
        stopwatch.elapsed,
        lessThan(budget),
        reason:
            'Provider Dashboard atas $transactionCount transaksi terlalu lambat',
      );
    },
  );

  test('filteredTransactionsProvider (Riwayat) tetap cepat', () async {
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWith((ref) async => txRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionsStreamProvider.future);
    container.read(historyMonthFilterProvider.notifier).state = '2024-06';

    final stopwatch = Stopwatch()..start();
    final filtered = container.read(filteredTransactionsProvider).value;
    stopwatch.stop();

    expect(filtered, isNotNull);
    expect(
      stopwatch.elapsed,
      lessThan(budget),
      reason:
          'filteredTransactionsProvider atas $transactionCount transaksi terlalu lambat',
    );
  });
}
