import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/providers.dart';
import '../../../shared/widgets/category_colors.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/export_format_sheet.dart';
import '../../export/application/export_controller.dart';
import '../application/dashboard_models.dart';
import '../application/dashboard_providers.dart';

/// Layar Dashboard (PRD §6.5): saldo total, ringkasan periode, grafik
/// donat distribusi kategori, grafik batang tren 6 bulan, serta ekspor
/// Excel/PDF (PRD §6.7) sesuai periode terpilih.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            key: const Key('export-button'),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export laporan',
            onPressed: () => _onExportTap(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Saldo Total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                balanceAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat: $e'),
                  data: (balance) => Text(
                    formatRupiah(balance),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _PeriodSelector(),
          const SizedBox(height: 12),
          const _PeriodSummaryRow(),
          const SizedBox(height: 32),
          Text(
            'Distribusi Pengeluaran',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _CategoryDonutChart(),
          const SizedBox(height: 32),
          Text(
            'Tren 6 Bulan Terakhir',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _TrendBarChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _onExportTap(BuildContext context, WidgetRef ref) async {
    final format = await showExportFormatSheet(context);
    if (format == null || !context.mounted) return;

    final transactions = ref.read(periodTransactionsProvider).value ?? [];
    final period = ref.read(dashboardPeriodProvider);
    final periodLabel = date_utils.monthLabel(period);

    if (!context.mounted) return;
    await exportTransactions(
      context: context,
      ref: ref,
      transactions: transactions,
      periodLabel: periodLabel,
      format: format,
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthsAsync = ref.watch(dashboardAvailableMonthsProvider);
    final selected = ref.watch(dashboardPeriodProvider);

    return monthsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (months) {
        return DropdownButtonFormField<String>(
          key: const Key('dashboard-period'),
          initialValue: months.contains(selected) ? selected : null,
          decoration: const InputDecoration(labelText: 'Periode'),
          items: months
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(date_utils.monthLabel(m)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(dashboardPeriodProvider.notifier).state = value;
            }
          },
        );
      },
    );
  }
}

class _PeriodSummaryRow extends ConsumerWidget {
  const _PeriodSummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(periodSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Gagal memuat ringkasan: $e'),
      data: (summary) {
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.arrow_downward_rounded,
                label: 'Pemasukan',
                value: summary.income,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.arrow_upward_rounded,
                label: 'Pengeluaran',
                value: summary.expense,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.balance_rounded,
                label: 'Selisih',
                value: summary.balance,
                color: summary.balance >= 0
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatCompactRupiah(value),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDonutChart extends ConsumerWidget {
  const _CategoryDonutChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesAsync = ref.watch(categoryBreakdownProvider);

    return slicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Gagal memuat grafik: $e'),
      data: (slices) {
        if (slices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Belum ada pengeluaran pada periode ini',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: slices.map((slice) {
                    final color = colorForCategory(slice.categoryId);
                    // Label selektif: hanya irisan cukup besar diberi
                    // label langsung, sisanya cukup lewat legend.
                    final showTitle = slice.percentage >= 0.08;
                    return PieChartSectionData(
                      value: slice.amount.toDouble(),
                      color: color,
                      radius: 56,
                      showTitle: showTitle,
                      title: '${(slice.percentage * 100).round()}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DonutLegend(slices: slices),
          ],
        );
      },
    );
  }
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({required this.slices});

  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: slices.map((slice) {
        final color = colorForCategory(slice.categoryId);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                iconForCategoryKey(slice.iconKey),
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  slice.categoryName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${(slice.percentage * 100).round()}% · ${formatRupiah(slice.amount)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TrendBarChart extends ConsumerWidget {
  const _TrendBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(sixMonthTrendProvider);

    return trendAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Gagal memuat grafik: $e'),
      data: (months) {
        final maxValue = months.fold<int>(
          0,
          (max, m) =>
              [max, m.income, m.expense].reduce((a, b) => a > b ? a : b),
        );
        // Sumbu Y dibulatkan ke angka bersih (marks-and-anatomy.md).
        final maxY = maxValue == 0 ? 1000.0 : _roundedMaxY(maxValue);

        return Column(
          children: [
            const _TrendLegend(),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.inkBorder, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) => Text(
                          formatCompactRupiah(value.round()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _shortMonthLabel(months[index].monthKey),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isIncome = rodIndex == 0;
                        return BarTooltipItem(
                          '${isIncome ? 'Pemasukan' : 'Pengeluaran'}\n${formatRupiah(rod.toY.round())}',
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: months.asMap().entries.map((entry) {
                    final m = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: m.income.toDouble(),
                          color: AppColors.income,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: m.expense.toDouble(),
                          color: AppColors.expense,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _roundedMaxY(int maxValue) {
    // Bulatkan ke atas ke kelipatan "bersih" terdekat (1/2/5 x 10^n).
    final magnitude = (maxValue == 0) ? 1 : _pow10Below(maxValue);
    final normalized = maxValue / magnitude;
    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }
    return niceNormalized * magnitude * 1.0;
  }

  int _pow10Below(int value) {
    var magnitude = 1;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    return magnitude;
  }

  String _shortMonthLabel(String monthKey) {
    const shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = int.parse(monthKey.split('-')[1]);
    return shortMonths[month - 1];
  }
}

class _TrendLegend extends StatelessWidget {
  const _TrendLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(context, AppColors.income, 'Pemasukan'),
        const SizedBox(width: 20),
        _legendDot(context, AppColors.expense, 'Pengeluaran'),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
