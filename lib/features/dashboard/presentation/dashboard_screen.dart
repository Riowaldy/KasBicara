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
import '../../../shared/widgets/asset_selector.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../home/presentation/voice_input_screen.dart';
import '../../scan/presentation/receipt_scan_flow.dart';
import '../../settings/presentation/language_dialog.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/dashboard_providers.dart';

/// Dashboard ringkas (PRD §6.5): saldo bersih aset aktif, transaksi terakhir,
/// dan satu tombol tambah data dengan tiga cara — suara, manual, atau pindai
/// struk.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: l10n.settingsLanguageTooltip,
            onPressed: () => showLanguageDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const AssetSelector(),
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
    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddEntrySheet(),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _AddAction.voice:
        // Alur suara lengkap (mic + transkrip live + draft) ada di layar
        // khusus yang dibuka di atas Dashboard.
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VoiceInputScreen()));
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

/// Lembar "Tambah Data" (PRD §6.5). Tombol mic dibuat paling menonjol di
/// puncak; di bawahnya "Isi manual" dan "Pindai struk" tampil berdampingan
/// sebagai kartu yang bisa digeser-geser seperti slide show.
class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _pageController = PageController(viewportFraction: 0.82);
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final slides = [
      _AddSlideCard(
        itemKey: const Key('add-manual'),
        icon: Icons.edit_rounded,
        title: l10n.addSheetManual,
        subtitle: l10n.addSheetManualSubtitle,
        onTap: () => Navigator.of(context).pop(_AddAction.manual),
      ),
      _AddSlideCard(
        itemKey: const Key('add-scan'),
        icon: Icons.receipt_long_rounded,
        title: l10n.addSheetScan,
        subtitle: l10n.addSheetScanSubtitle,
        onTap: () => Navigator.of(context).pop(_AddAction.scan),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.addSheetTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            // Tombol mic — paling menonjol.
            Semantics(
              button: true,
              label: l10n.addSheetVoice,
              child: GestureDetector(
                key: const Key('add-voice'),
                onTap: () => Navigator.of(context).pop(_AddAction.voice),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 52,
                    color: AppColors.inkBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.addSheetVoice, style: theme.textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                l10n.addSheetVoiceSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(indent: 24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.addSheetOr,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider(endIndent: 24)),
              ],
            ),
            const SizedBox(height: 16),
            // Slide show "Isi manual" / "Pindai struk" — digeser-geser.
            SizedBox(
              height: 176,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: slides,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.gold : AppColors.inkBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSlideCard extends StatelessWidget {
  const _AddSlideCard({
    required this.itemKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key itemKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: AppColors.inkSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: itemKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.inkSurface,
                  child: Icon(icon, color: AppColors.gold, size: 30),
                ),
                const SizedBox(height: 14),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetBalanceCard extends ConsumerWidget {
  const _NetBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(balanceProvider);
    final activeAsset = ref.watch(activeAssetProvider);
    final assets = ref.watch(assetsStreamProvider).valueOrNull ?? const [];

    var scopeLabel = l10n.assetSelectorAll;
    if (activeAsset != null) {
      final match = assets.where((a) => a.id == activeAsset);
      if (match.isNotEmpty) scopeLabel = assetDisplayName(match.first, l10n);
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
