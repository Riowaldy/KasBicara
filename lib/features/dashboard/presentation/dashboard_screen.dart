import 'package:flutter/material.dart';

/// Layar Dashboard — skeleton. Grafik donat kategori & tren 6 bulan
/// dibangun di Fase 4.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Text(
          'Grafik akan tampil di sini',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
