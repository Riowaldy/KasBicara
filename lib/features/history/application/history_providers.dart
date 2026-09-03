import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers.dart';

/// Filter bulan aktif di layar Riwayat. `null` berarti "semua bulan".
final historyMonthFilterProvider = StateProvider<String?>((ref) => null);

/// Filter kategori aktif di layar Riwayat. `null` berarti "semua kategori".
final historyCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Transaksi setelah difilter — reaktif terhadap data & filter aktif (FR-7).
/// Filter pocket memakai [activePocketProvider] (selector header di 3 layar),
/// menyatu dengan filter bulan & kategori (konsep "Pocket KasBicara" §08).
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final monthFilter = ref.watch(historyMonthFilterProvider);
  final categoryFilter = ref.watch(historyCategoryFilterProvider);
  final activePocket = ref.watch(activePocketProvider);

  return txAsync.whenData(
    (list) => list.where((t) {
      if (monthFilter != null && toMonthKey(t.date) != monthFilter) {
        return false;
      }
      if (categoryFilter != null && t.category != categoryFilter) {
        return false;
      }
      if (activePocket != null && t.pocketId != activePocket) {
        return false;
      }
      return true;
    }).toList(),
  );
});
