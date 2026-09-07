import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assets/presentation/asset_manage_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../l10n/app_localizations.dart';

/// Tab aktif pada bottom nav utama — dijadikan provider agar layar lain bisa
/// berpindah tab secara terprogram (mis. tombol "Lihat semua" di Dashboard
/// yang melompat ke Riwayat). 0 = Dashboard, 1 = Riwayat, 2 = Aset.
final rootTabProvider = StateProvider<int>((ref) => 0);

/// Kerangka navigasi utama: bottom nav 3 tab (Dashboard, Riwayat, Aset).
class RootScaffold extends ConsumerWidget {
  const RootScaffold({super.key});

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    AssetManageScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(rootTabProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        // 3 item — kunci ke fixed agar semua label tetap tampil.
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => ref.read(rootTabProvider.notifier).state = i,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: l10n.navRiwayat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: l10n.navAset,
          ),
        ],
      ),
    );
  }
}
