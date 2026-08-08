import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction_model.dart';

/// Ratakan [transactions] (harus sudah terurut tanggal terbaru -> terlama)
/// menjadi satu daftar campuran header tanggal ([DateTime]) & [Transaction],
/// siap dipakai `ListView.builder` — lihat catatan performa di
/// `history_screen.dart` (NFR skalabilitas ±10.000 transaksi, PRD §8).
List<Object> groupTransactionsForList(List<Transaction> transactions) {
  final items = <Object>[];
  String? lastDateKey;
  for (final t in transactions) {
    final key = toDateString(t.date);
    if (key != lastDateKey) {
      items.add(t.date);
      lastDateKey = key;
    }
    items.add(t);
  }
  return items;
}
