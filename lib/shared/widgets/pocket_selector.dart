import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pocket_model.dart';
import '../../data/providers.dart';
import '../../features/pockets/presentation/pocket_manage_screen.dart';
import '../../l10n/app_localizations.dart';
import 'pocket_icons.dart';

/// Nama pocket untuk ditampilkan: Pocket Utama memakai nama terlokalisasi
/// (konsep "Pocket KasBicara" §02 & keputusan terbuka #1), sisanya memakai
/// nama yang disimpan pengguna.
String pocketDisplayName(Pocket pocket, AppLocalizations l10n) =>
    pocket.isDefault ? l10n.pocketMainName : pocket.name;

/// Baris chip pemilih pocket — dipasang di header Beranda, Riwayat, &
/// Dashboard. Mengubah [activePocketProvider] (sumber kebenaran tunggal).
/// Chip terakhir membuka layar Kelola Pocket.
class PocketSelector extends ConsumerWidget {
  const PocketSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pocketsAsync = ref.watch(pocketsStreamProvider);
    final active = ref.watch(activePocketProvider);

    final pockets = pocketsAsync.valueOrNull ?? const <Pocket>[];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _PocketChip(
            label: l10n.pocketSelectorAll,
            selected: active == null,
            onSelected: () =>
                ref.read(activePocketProvider.notifier).state = null,
          ),
          for (final pocket in pockets)
            _PocketChip(
              label: pocketDisplayName(pocket, l10n),
              icon: iconForPocketKey(pocket.icon),
              selected: active == pocket.id,
              onSelected: () =>
                  ref.read(activePocketProvider.notifier).state = pocket.id,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: Text(l10n.pocketManageTitle),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PocketManageScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PocketChip extends StatelessWidget {
  const _PocketChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
