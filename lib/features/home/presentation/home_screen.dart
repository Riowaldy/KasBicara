import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/providers.dart';
import '../../transactions/presentation/transaction_form_screen.dart';

/// Layar Beranda. Tombol mic besar fungsional di Fase 3; untuk saat ini
/// jalur input manual sudah lengkap end-to-end (PRD §6.3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('KasBicara')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            balanceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Gagal memuat saldo: $e'),
              data: (balance) => Text(
                formatRupiah(balance),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo saat ini',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const _MicButtonPlaceholder(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _openManualForm(context),
              child: const Text('Tambah manual'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManualForm(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TransactionFormScreen()));
  }
}

class _MicButtonPlaceholder extends StatelessWidget {
  const _MicButtonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.mic, size: 40, color: AppColors.inkBackground),
    );
  }
}
