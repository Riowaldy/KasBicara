import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/history_providers.dart';

/// Layar Riwayat Transaksi (PRD §6.6): dikelompokkan per tanggal (terbaru
/// di atas), filter bulan & kategori, aksi edit/hapus.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
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
                      'Belum ada transaksi',
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
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  decoration: const InputDecoration(labelText: 'Bulan'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua')),
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
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua')),
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
    // transactions sudah terurut tanggal terbaru -> terlama dari repository.
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      groups.putIfAbsent(date_utils.toDateString(t.date), () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: groups.entries.map((entry) {
        final date = entry.value.first.date;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                date_utils.dateLabel(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...entry.value.map((t) => _TransactionTile(transaction: t)),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '-';

    return Dismissible(
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
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
