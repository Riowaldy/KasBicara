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

/// Lembar "Tambah Data" (PRD §6.5). Ketiga cara — Lewat suara, Isi manual,
/// Pindai struk — tampil bersama: baris tab bernama di atas + carousel yang
/// bisa digeser. Halaman pertama (default) tetap "Lewat suara".
class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _pageController = PageController(viewportFraction: 0.84);
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final tabs = [
      (
        key: const Key('add-tab-voice'),
        icon: Icons.mic_rounded,
        label: l10n.addSheetVoice,
      ),
      (
        key: const Key('add-tab-manual'),
        icon: Icons.edit_rounded,
        label: l10n.addSheetManual,
      ),
      (
        key: const Key('add-tab-scan'),
        icon: Icons.receipt_long_rounded,
        label: l10n.addSheetScan,
      ),
    ];

    final slides = [
      _VoiceSlide(onTap: () => Navigator.of(context).pop(_AddAction.voice)),
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
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.addSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            // Tab ikon — ringkas; yang aktif melebar menampilkan namanya.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    _AddModeTab(
                      tabKey: tabs[i].key,
                      icon: tabs[i].icon,
                      label: tabs[i].label,
                      selected: _page == i,
                      onTap: () => _goTo(i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Carousel — bisa digeser ke kiri/kanan.
            SizedBox(
              height: 236,
              child: PageView(
                key: const Key('add-entry-pager'),
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: slides,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addSheetSwipeHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu tab di puncak lembar "Tambah Data": hanya ikon saat tidak aktif,
/// melebar jadi ikon + nama saat aktif.
class _AddModeTab extends StatelessWidget {
  const _AddModeTab({
    required this.tabKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key tabKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: Material(
            color: selected ? AppColors.gold : AppColors.inkSurfaceAlt,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              key: tabKey,
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 16 : 13,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? AppColors.inkBackground
                          : AppColors.textMuted,
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkBackground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu "Lewat suara" di dalam carousel — mic emas menonjol + contoh ucapan.
class _VoiceSlide extends StatelessWidget {
  const _VoiceSlide({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: AppColors.inkSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('add-voice'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Semantics(
            button: true,
            label: l10n.addSheetVoice,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      size: 42,
                      color: AppColors.inkBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.addSheetVoice, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    l10n.homeVoiceExampleTitle,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeVoiceExampleExpense,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    l10n.homeVoiceExampleIncome,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
