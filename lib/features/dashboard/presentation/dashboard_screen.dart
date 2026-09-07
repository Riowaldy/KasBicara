import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/root_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/pocket_selector.dart';
import '../../home/application/voice_input_controller.dart';
import '../../scan/presentation/receipt_scan_flow.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/dashboard_providers.dart';

/// Dashboard ringkas (PRD §6.5): saldo bersih pocket aktif, transaksi
/// terakhir, dan satu tombol tambah data dengan tiga cara — suara, manual,
/// atau pindai struk.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const PocketSelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: const [
                _NetBalanceCard(),
                SizedBox(height: 28),
                _RecentTransactionsSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('dashboard-add-fab'),
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addSheetTitle),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.addSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              key: const Key('add-voice'),
              leading: const Icon(Icons.mic_rounded),
              title: Text(l10n.addSheetVoice),
              subtitle: Text(l10n.addSheetVoiceSubtitle),
              onTap: () => Navigator.of(context).pop(_AddAction.voice),
            ),
            ListTile(
              key: const Key('add-manual'),
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.addSheetManual),
              subtitle: Text(l10n.addSheetManualSubtitle),
              onTap: () => Navigator.of(context).pop(_AddAction.manual),
            ),
            ListTile(
              key: const Key('add-scan'),
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(l10n.addSheetScan),
              subtitle: Text(l10n.addSheetScanSubtitle),
              onTap: () => Navigator.of(context).pop(_AddAction.scan),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _AddAction.voice:
        // Alur suara lengkap sudah ada di Beranda — lompat ke sana lalu mulai
        // mendengarkan; listener Beranda menangani transkrip → kartu draft.
        ref.read(rootTabProvider.notifier).state = 0;
        final voice = ref.read(voiceInputControllerProvider.notifier);
        if (ref.read(voiceInputControllerProvider).status !=
            VoiceInputStatus.listening) {
          await voice.startListening();
        }
      case _AddAction.manual:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        );
      case _AddAction.scan:
        await startReceiptScan(context);
    }
  }
}

enum _AddAction { voice, manual, scan }

class _NetBalanceCard extends ConsumerWidget {
  const _NetBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(balanceProvider);
    final activePocket = ref.watch(activePocketProvider);
    final pockets = ref.watch(pocketsStreamProvider).valueOrNull ?? const [];

    var scopeLabel = l10n.pocketSelectorAll;
    if (activePocket != null) {
      final match = pockets.where((p) => p.id == activePocket);
      if (match.isNotEmpty) scopeLabel = pocketDisplayName(match.first, l10n);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Text(
              l10n.dashboardNetBalance,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            balanceAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text(l10n.dashboardBalanceError),
              data: (balance) => Text(
                formatRupiah(balance),
                key: const Key('dashboard-net-balance'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: balance < 0
                      ? AppColors.expenseText
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(scopeLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.dashboardRecentTransactions,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => ref.read(rootTabProvider.notifier).state = 1,
              child: Text(l10n.dashboardSeeAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        recentAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.dashboardBalanceError),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.historyEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final t in transactions)
                  _RecentTile(key: Key('recent-${t.id}'), transaction: t),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecentTile extends ConsumerWidget {
  const _RecentTile({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final category = categoriesAsync.maybeWhen(
      data: (categories) =>
          categories.where((c) => c.id == transaction.category).firstOrNull,
      orElse: () => null,
    );

    final isIncome = transaction.type == TransactionType.masuk;
    final amountColor = isIncome ? AppColors.incomeText : AppColors.expenseText;
    final sign = isIncome ? '+' : '-';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.inkSurfaceAlt,
        child: Icon(
          iconForCategoryKey(category?.icon ?? 'other'),
          color: AppColors.gold,
        ),
      ),
      title: Text(category?.name ?? transaction.category),
      subtitle: Text(
        transaction.note?.isNotEmpty == true
            ? transaction.note!
            : date_utils.dateLabel(transaction.date),
      ),
      trailing: Text(
        '$sign${formatRupiah(transaction.amount)}',
        style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionFormScreen(initial: transaction),
        ),
      ),
    );
  }
}
