import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Layar Beranda — skeleton. Tombol mic besar akan menjadi fungsional
/// di Fase 3 (Input & Parsing Suara); untuk saat ini murni placeholder visual.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KasBicara')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rp 0', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Saldo saat ini',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            _MicButtonPlaceholder(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: null,
              child: Text(
                'Tambah manual',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
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
