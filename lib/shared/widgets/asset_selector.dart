import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/asset_model.dart';
import '../../data/models/asset_type.dart';
import '../../data/providers.dart';
import '../../features/assets/presentation/asset_manage_screen.dart';
import '../../l10n/app_localizations.dart';
import 'asset_icons.dart';

/// Nama aset untuk ditampilkan: Aset Utama memakai nama terlokalisasi,
/// sisanya memakai nama yang disimpan pengguna.
String assetDisplayName(Asset asset, AppLocalizations l10n) =>
    asset.isDefault ? l10n.assetMainName : asset.name;

/// Label terlokalisasi untuk kategori aset (dipakai form & layar kelola).
String assetTypeLabel(AssetType type, AppLocalizations l10n) => switch (type) {
  AssetType.tunai => l10n.assetTypeTunai,
  AssetType.bank => l10n.assetTypeBank,
  AssetType.eWallet => l10n.assetTypeEwallet,
  AssetType.bankDigital => l10n.assetTypeBankDigital,
  AssetType.kartuKredit => l10n.assetTypeKartuKredit,
  AssetType.investasi => l10n.assetTypeInvestasi,
  AssetType.lainnya => l10n.assetTypeLainnya,
};

/// Baris chip pemilih aset — dipasang di header Dashboard & Riwayat. Mengubah
/// [activeAssetProvider] (sumber kebenaran tunggal konteks aktif). Chip
/// terakhir membuka layar Kelola Aset.
class AssetSelector extends ConsumerWidget {
  const AssetSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final assetsAsync = ref.watch(assetsStreamProvider);
    final active = ref.watch(activeAssetProvider);

    final assets = assetsAsync.valueOrNull ?? const <Asset>[];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _AssetChip(
            label: l10n.assetSelectorAll,
            selected: active == null,
            onSelected: () =>
                ref.read(activeAssetProvider.notifier).state = null,
          ),
          for (final asset in assets)
            _AssetChip(
              label: assetDisplayName(asset, l10n),
              icon: iconForAssetKey(asset.icon),
              selected: active == asset.id,
              onSelected: () =>
                  ref.read(activeAssetProvider.notifier).state = asset.id,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: Text(l10n.assetManageTitle),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AssetManageScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetChip extends StatelessWidget {
  const _AssetChip({
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
