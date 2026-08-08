import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/export_format_sheet.dart';
import '../../export/application/export_controller.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/history_providers.dart';
import '../application/transaction_grouping.dart';

/// Layar Riwayat Transaksi (PRD §6.6): dikelompokkan per tanggal (terbaru
/// di atas), filter bulan & kategori, aksi edit/hapus, ekspor Excel/PDF
/// (PRD §6.7) sesuai filter aktif.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filteredAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            key: const Key('export-button'),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: l10n.exportTooltip,
            onPressed: () => _onExportTap(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const _FilterBar(),
          const Divider(height: 1),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.historyEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return _GroupedTransactionList(transactions: transactions);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onExportTap(BuildContext context, WidgetRef ref) async {
    final format = await showExportFormatSheet(context);
    if (format == null || !context.mounted) return;

    final transactions = ref.read(filteredTransactionsProvider).value ?? [];
    final monthFilter = ref.read(historyMonthFilterProvider);
    final categoryFilter = ref.read(historyCategoryFilterProvider);
    final categories = ref.read(categoriesProvider).value ?? [];

    final monthLabelText = monthFilter != null
        ? date_utils.monthLabel(monthFilter)
        : AppLocalizations.of(context)!.exportAllMonths;
    final categoryName = categoryFilter == null
        ? null
        : categories
              .where((c) => c.id == categoryFilter)
              .map((c) => c.name)
              .firstOrNull;
    final periodLabel = categoryName != null
        ? '$monthLabelText · $categoryName'
        : monthLabelText;

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

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final monthsAsync = ref.watch(availableMonthsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedMonth = ref.watch(historyMonthFilterProvider);
    final selectedCategory = ref.watch(historyCategoryFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: monthsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (months) {
                return DropdownButtonFormField<String?>(
                  key: const Key('month-filter'),
                  initialValue: selectedMonth,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.historyMonthLabel,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...months.map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(date_utils.monthLabel(m)),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(historyMonthFilterProvider.notifier).state =
                          value,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (categories) {
                return DropdownButtonFormField<String?>(
                  key: const Key('category-filter'),
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.historyCategoryLabel,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...categories.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(historyCategoryFilterProvider.notifier).state =
                          value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  const _GroupedTransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    // Diratakan jadi satu List<Object> (header tanggal diselingi transaksi)
    // lalu dirender via ListView.builder — bukan ListView(children: ...)
    // yang membangun SEMUA widget di muka. Penting di ±10.000 transaksi
    // (NFR skalabilitas data, PRD §8): builder hanya me-render item yang
    // benar-benar terlihat + sedikit buffer.
    final items = groupTransactionsForList(transactions);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              date_utils.dateLabel(item),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        return _TransactionTile(transaction: item as Transaction);
      },
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoryName = categoriesAsync.maybeWhen(
      data: (categories) => categories
          .where((c) => c.id == transaction.category)
          .map((c) => c.name)
          .firstOrNull,
      orElse: () => null,
    );
    final categoryIconKey = categoriesAsync.maybeWhen(
      data: (categories) => categories
          .where((c) => c.id == transaction.category)
          .map((c) => c.icon)
          .firstOrNull,
      orElse: () => null,
    );

    final isIncome = transaction.type == TransactionType.masuk;
    // *Text varian (bukan income/expense polos) — nominal ini teks biasa,
    // butuh kontras AA 4.5:1, bukan cuma ambang grafis 3:1.
    final amountColor = isIncome ? AppColors.incomeText : AppColors.expenseText;
    final sign = isIncome ? '+' : '-';

    // Swipe-to-delete tidak bisa dilakukan pengguna screen reader — sediakan
    // aksi aksesibel setara lewat customSemanticsActions (muncul di menu
    // aksi TalkBack/VoiceOver), memakai alur konfirmasi yang sama.
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.actionDeleteTransaction): () =>
            _deleteWithConfirmation(context, ref),
      },
      child: Dismissible(
        key: ValueKey('tx-${transaction.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppColors.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) async {
          final repo = await ref.read(transactionRepositoryProvider.future);
          await repo.delete(transaction.id);
        },
        child: ListTile(
          key: Key('tx-tile-${transaction.id}'),
          leading: CircleAvatar(
            backgroundColor: AppColors.inkSurfaceAlt,
            child: Icon(
              iconForCategoryKey(categoryIconKey ?? 'other'),
              color: AppColors.gold,
            ),
          ),
          title: Text(categoryName ?? transaction.category),
          subtitle: transaction.note != null ? Text(transaction.note!) : null,
          trailing: Text(
            '$sign${formatRupiah(transaction.amount)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionFormScreen(initial: transaction),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteWithConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;
    final repo = await ref.read(transactionRepositoryProvider.future);
    await repo.delete(transaction.id);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteConfirmTitle),
        content: Text(l10n.historyDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
