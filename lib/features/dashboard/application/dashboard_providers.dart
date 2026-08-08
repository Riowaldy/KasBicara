import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';
import 'dashboard_models.dart';

/// Periode (`YYYY-MM`) terpilih di Dashboard — default bulan berjalan
/// (PRD §6.5).
final dashboardPeriodProvider = StateProvider<String>(
  (ref) => toMonthKey(DateTime.now()),
);

/// Opsi periode yang bisa dipilih: bulan berjalan selalu tersedia (walau
/// belum ada transaksinya) + semua bulan yang punya data.
final dashboardAvailableMonthsProvider = Provider<AsyncValue<List<String>>>((
  ref,
) {
  final monthsAsync = ref.watch(availableMonthsProvider);
  final currentMonth = toMonthKey(DateTime.now());
  return monthsAsync.whenData((months) {
    final all = {currentMonth, ...months}.toList()
      ..sort((a, b) => b.compareTo(a));
    return all;
  });
});

/// Ringkasan pemasukan/pengeluaran/selisih periode terpilih.
final periodSummaryProvider = Provider<AsyncValue<PeriodSummary>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final period = ref.watch(dashboardPeriodProvider);

  return txAsync.whenData((list) {
    var income = 0;
    var expense = 0;
    for (final t in list) {
      if (toMonthKey(t.date) != period) continue;
      if (t.type == TransactionType.masuk) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return PeriodSummary(income: income, expense: expense);
  });
});

/// Distribusi pengeluaran per kategori pada periode terpilih (grafik donat).
/// Diurutkan dari terbesar; warna tiap irisan mengikuti ENTITAS kategori
/// (lihat `category_colors.dart`), bukan urutan/rank di sini.
final categoryBreakdownProvider = Provider<AsyncValue<List<CategorySlice>>>((
  ref,
) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final period = ref.watch(dashboardPeriodProvider);

  if (txAsync is AsyncLoading || categoriesAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (txAsync.hasError) {
    return AsyncValue.error(txAsync.error!, txAsync.stackTrace!);
  }
  if (categoriesAsync.hasError) {
    return AsyncValue.error(
      categoriesAsync.error!,
      categoriesAsync.stackTrace!,
    );
  }

  final transactions = txAsync.value!;
  final categoryById = {for (final c in categoriesAsync.value!) c.id: c};

  final totals = <String, int>{};
  for (final t in transactions) {
    if (t.type != TransactionType.keluar) continue;
    if (toMonthKey(t.date) != period) continue;
    totals[t.category] = (totals[t.category] ?? 0) + t.amount;
  }

  final totalAmount = totals.values.fold<int>(0, (a, b) => a + b);
  final slices = totals.entries.map((entry) {
    final category = categoryById[entry.key];
    return CategorySlice(
      categoryId: entry.key,
      categoryName: category?.name ?? entry.key,
      iconKey: category?.icon ?? 'other',
      amount: entry.value,
      percentage: totalAmount == 0 ? 0 : entry.value / totalAmount,
    );
  }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

  return AsyncValue.data(slices);
});

/// Tren pemasukan vs pengeluaran 6 bulan terakhir (termasuk bulan
/// berjalan), untuk grafik batang. Bulan tanpa transaksi tetap tampil (0).
final sixMonthTrendProvider = Provider<AsyncValue<List<MonthlyTotals>>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);

  return txAsync.whenData((list) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return toMonthKey(d);
    });

    final incomeByMonth = {for (final m in months) m: 0};
    final expenseByMonth = {for (final m in months) m: 0};

    for (final t in list) {
      final key = toMonthKey(t.date);
      if (!incomeByMonth.containsKey(key)) continue;
      if (t.type == TransactionType.masuk) {
        incomeByMonth[key] = incomeByMonth[key]! + t.amount;
      } else {
        expenseByMonth[key] = expenseByMonth[key]! + t.amount;
      }
    }

    return months
        .map(
          (m) => MonthlyTotals(
            monthKey: m,
            income: incomeByMonth[m]!,
            expense: expenseByMonth[m]!,
          ),
        )
        .toList();
  });
});
