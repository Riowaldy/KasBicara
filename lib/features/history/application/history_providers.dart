import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers.dart';

/// Filter bulan aktif di layar Riwayat. `null` berarti "semua bulan".
final historyMonthFilterProvider = StateProvider<String?>((ref) => null);

/// Filter kategori aktif di layar Riwayat. `null` berarti "semua kategori".
final historyCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Transaksi setelah difilter — reaktif terhadap data & filter aktif (FR-7).
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final monthFilter = ref.watch(historyMonthFilterProvider);
  final categoryFilter = ref.watch(historyCategoryFilterProvider);

  return txAsync.whenData(
    (list) => list.where((t) {
      if (monthFilter != null && toMonthKey(t.date) != monthFilter) {
        return false;
      }
      if (categoryFilter != null && t.category != categoryFilter) {
        return false;
      }
      return true;
    }).toList(),
  );
});
