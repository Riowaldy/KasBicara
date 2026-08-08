import 'package:flutter/foundation.dart';

/// Ringkasan pemasukan/pengeluaran/selisih untuk satu periode (PRD §6.5).
@immutable
class PeriodSummary {
  const PeriodSummary({required this.income, required this.expense});

  final int income;
  final int expense;

  int get balance => income - expense;
}

/// Satu irisan grafik donat: total pengeluaran satu kategori pada periode
/// terpilih.
@immutable
class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;
  final String iconKey;
  final int amount;

  /// 0.0–1.0 dari total pengeluaran periode tersebut.
  final double percentage;
}

/// Total pemasukan & pengeluaran satu bulan — satu titik di grafik tren.
@immutable
class MonthlyTotals {
  const MonthlyTotals({
    required this.monthKey,
    required this.income,
    required this.expense,
  });

  final String monthKey;
  final int income;
  final int expense;
}
