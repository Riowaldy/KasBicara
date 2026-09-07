import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assets/presentation/asset_manage_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../l10n/app_localizations.dart';

/// Tab aktif pada bottom nav utama — dijadikan provider agar layar lain bisa
/// berpindah tab secara terprogram (mis. tombol "Tambah via suara" di
/// Dashboard yang melompat ke Beranda). 0 = Beranda, 1 = Riwayat,
/// 2 = Dashboard, 3 = Aset.
final rootTabProvider = StateProvider<int>((ref) => 0);

/// Kerangka navigasi utama: bottom nav 4 tab (Beranda, Riwayat, Dashboard, Aset).
class RootScaffold extends ConsumerWidget {
  const RootScaffold({super.key});

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    DashboardScreen(),
    AssetManageScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(rootTabProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        // 4 item — kunci ke fixed agar semua label tetap tampil.
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => ref.read(rootTabProvider.notifier).state = i,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.mic_none_rounded),
            label: l10n.navBeranda,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: l10n.navRiwayat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart_rounded),
            label: l10n.navDashboard,
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
