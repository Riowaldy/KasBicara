import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';

/// Granularitas filter waktu di layar Riwayat — relatif terhadap hari ini.
enum HistoryPeriod { daily, weekly, monthly, yearly, all }

/// Filter waktu aktif. Default [HistoryPeriod.monthly] = "bulan ini".
final historyPeriodFilterProvider = StateProvider<HistoryPeriod>(
  (ref) => HistoryPeriod.monthly,
);

/// Filter tipe transaksi aktif. `null` = semua tipe.
final historyTypeFilterProvider = StateProvider<TransactionType?>(
  (ref) => null,
);

/// Filter aset aktif. `null` = semua aset.
final historyAssetFilterProvider = StateProvider<String?>((ref) => null);

/// Filter kategori aktif di layar Riwayat. `null` berarti "semua kategori".
final historyCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Rentang `[start, end)` (tanggal‑kalender) untuk [period] relatif ke [now].
/// `null` untuk [HistoryPeriod.all] (tanpa batas). Minggu dimulai Senin.
({DateTime start, DateTime end})? historyPeriodRange(
  HistoryPeriod period,
  DateTime now,
) {
  final today = dateOnly(now);
  switch (period) {
    case HistoryPeriod.daily:
      return (start: today, end: today.add(const Duration(days: 1)));
    case HistoryPeriod.weekly:
      final monday = today.subtract(Duration(days: today.weekday - 1));
      return (start: monday, end: monday.add(const Duration(days: 7)));
    case HistoryPeriod.monthly:
      return (
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1),
      );
    case HistoryPeriod.yearly:
      return (
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year + 1, 1, 1),
      );
    case HistoryPeriod.all:
      return null;
  }
}

/// Transaksi setelah difilter — reaktif terhadap data & filter aktif (FR-7).
/// Menggabungkan filter waktu, tipe, aset, kategori (di file ini) dengan
/// filter pocket ([activePocketProvider], selector header di 3 layar).
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final period = ref.watch(historyPeriodFilterProvider);
  final typeFilter = ref.watch(historyTypeFilterProvider);
  final assetFilter = ref.watch(historyAssetFilterProvider);
  final categoryFilter = ref.watch(historyCategoryFilterProvider);
  final activePocket = ref.watch(activePocketProvider);

  final range = historyPeriodRange(period, DateTime.now());

  return txAsync.whenData(
    (list) => list.where((t) {
      if (range != null) {
        final d = dateOnly(t.date);
        if (d.isBefore(range.start) || !d.isBefore(range.end)) return false;
      }
      if (typeFilter != null && t.type != typeFilter) return false;
      if (assetFilter != null && t.assetId != assetFilter) return false;
      if (categoryFilter != null && t.category != categoryFilter) return false;
      if (activePocket != null && t.pocketId != activePocket) return false;
      return true;
    }).toList(),
  );
});
