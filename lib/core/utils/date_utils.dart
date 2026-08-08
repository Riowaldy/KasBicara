// Util tanggal untuk representasi `date` transaksi sebagai string
// `YYYY-MM-DD` (sesuai skema PRD §9), lepas dari komponen waktu/timezone.

/// Format [date] menjadi string `YYYY-MM-DD`.
String toDateString(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Buang komponen jam/menit/detik — hanya sisakan tanggal kalender.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Kunci bulan `YYYY-MM`, dipakai untuk filter riwayat per bulan (FR-7).
String toMonthKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$y-$m';
}
