import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../l10n/app_localizations.dart';

/// Kerangka navigasi utama: bottom nav 3 tab (Beranda, Riwayat, Dashboard).
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  static const _screens = [HomeScreen(), HistoryScreen(), DashboardScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
        ],
      ),
    );
  }
}
