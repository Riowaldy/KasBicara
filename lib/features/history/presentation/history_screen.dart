import 'package:flutter/material.dart';

/// Layar Riwayat Transaksi — skeleton. Daftar transaksi, filter bulan &
/// kategori, serta aksi hapus/edit dibangun di Fase 2.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: Center(
        child: Text(
          'Belum ada transaksi',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
