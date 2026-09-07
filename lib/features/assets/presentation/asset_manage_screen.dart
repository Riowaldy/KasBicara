import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../data/models/asset_model.dart';
import '../../../data/models/asset_type.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/asset_icons.dart';
import '../../../shared/widgets/asset_selector.dart';

/// Layar "Kelola Aset": daftar aset + saldo, tambah/ubah/hapus, susun ulang,
/// dan menandai "Sumber Aset Utama". Aset Utama bawaan terkunci di posisi
/// teratas dan tidak dapat dihapus.
class AssetManageScreen extends ConsumerWidget {
  const AssetManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final assetsAsync = ref.watch(assetsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assetManageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        // Tag unik — layar ini kini ikut selalu ter-mount di IndexedStack
        // bottom-nav bersama FAB Dashboard (tag default akan bentrok).
        heroTag: 'asset-manage-fab',
        onPressed: () => _addAsset(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.assetAddTitle),
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat aset: $e')),
        data: (assets) {
          final main = assets.firstWhere(
            (a) => a.isDefault,
            orElse: () => const Asset(
              id: kMainAssetId,
              name: 'Aset Utama',
              icon: 'cash',
              type: AssetType.tunai,
              isDefault: true,
              isPrimary: true,
              sortOrder: 0,
            ),
          );
          final others = assets.where((a) => !a.isDefault).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  l10n.assetManageHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _AssetRow(
                asset: main,
                onEdit: () => _editAsset(context, ref, main),
                onSetPrimary: main.isPrimary
                    ? null
                    : () => _setPrimary(ref, main),
              ),
              const Divider(height: 1),
              if (others.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    l10n.assetEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: others.length,
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) =>
                      _reorder(ref, others, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final asset = others[index];
                    return _AssetRow(
                      key: ValueKey(asset.id),
                      asset: asset,
                      dragIndex: index,
                      onEdit: () => _editAsset(context, ref, asset),
                      onSetPrimary: asset.isPrimary
                          ? null
                          : () => _setPrimary(ref, asset),
                      // Sumber Aset Utama tidak dapat dihapus — tandai aset
                      // lain sebagai Utama lebih dulu.
                      onDelete: asset.isPrimary
                          ? null
                          : () => _deleteAsset(context, ref, asset),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addAsset(BuildContext context, WidgetRef ref) async {
    final result = await _showAssetForm(context);
    if (result == null) return;
    final repo = await ref.read(assetRepositoryProvider.future);
    final maxSort = (ref.read(assetsStreamProvider).valueOrNull ?? [])
        .fold<int>(0, (m, a) => a.sortOrder > m ? a.sortOrder : m);
    await repo.create(
      Asset(
        id: generateId(),
        name: result.name,
        icon: result.icon,
        type: result.type,
        isDefault: false,
        isPrimary: false,
        sortOrder: maxSort + 1,
      ),
    );
  }

  Future<void> _editAsset(
    BuildContext context,
    WidgetRef ref,
    Asset asset,
  ) async {
    final result = await _showAssetForm(context, initial: asset);
    if (result == null) return;
    final repo = await ref.read(assetRepositoryProvider.future);
    await repo.update(
      asset.copyWith(
        // Nama Aset Utama tidak dapat diubah (dirender dari l10n).
        name: asset.isDefault ? null : result.name,
        icon: result.icon,
        type: result.type,
      ),
    );
  }

  Future<void> _setPrimary(WidgetRef ref, Asset asset) async {
    final repo = await ref.read(assetRepositoryProvider.future);
    await repo.setPrimary(asset.id);
  }

  Future<void> _deleteAsset(
    BuildContext context,
    WidgetRef ref,
    Asset asset,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final txCount = (ref.read(transactionsStreamProvider).valueOrNull ?? [])
        .where((t) => t.assetId == asset.id)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assetDeleteConfirmTitle),
        content: Text(
          txCount == 0
              ? l10n.assetDeleteConfirmEmpty(asset.name)
              : l10n.assetDeleteConfirmReassign(txCount, asset.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (txCount > 0) {
      final txRepo = await ref.read(transactionRepositoryProvider.future);
      await txRepo.reassignAsset(
        fromAssetId: asset.id,
        toAssetId: ref.read(primaryAssetIdProvider),
      );
    }
    final repo = await ref.read(assetRepositoryProvider.future);
    await repo.delete(asset.id);
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<Asset> others,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = [...others];
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final repo = await ref.read(assetRepositoryProvider.future);
    for (var i = 0; i < reordered.length; i++) {
      final desiredSort = i + 1; // Aset Utama menempati 0.
      if (reordered[i].sortOrder != desiredSort) {
        await repo.update(reordered[i].copyWith(sortOrder: desiredSort));
      }
    }
  }
}

/// Hasil form aset (nama + kunci ikon + tipe).
class _AssetFormResult {
  const _AssetFormResult(this.name, this.icon, this.type);
  final String name;
  final String icon;
  final AssetType type;
}

Future<_AssetFormResult?> _showAssetForm(
  BuildContext context, {
  Asset? initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial?.name ?? '');
  final formKey = GlobalKey<FormState>();
  var selectedType = initial?.type ?? AssetType.tunai;
  var selectedIcon = initial?.icon ?? selectedType.defaultIconKey;
  // Sekali pengguna memilih ikon sendiri, berhenti menyarankan ikon dari tipe.
  var iconTouched = initial != null;
  final isMain = initial?.isDefault ?? false;

  return showDialog<_AssetFormResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(initial == null ? l10n.assetAddTitle : l10n.assetEditTitle),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMain)
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l10n.assetNameLabel),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.assetNameError
                        : null,
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AssetType>(
                  key: const Key('asset-type-dropdown'),
                  initialValue: selectedType,
                  decoration: InputDecoration(labelText: l10n.assetTypeLabel),
                  items: [
                    for (final t in AssetType.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(assetTypeLabel(t, l10n)),
                      ),
                  ],
                  onChanged: (t) {
                    if (t == null) return;
                    setState(() {
                      selectedType = t;
                      if (!iconTouched) selectedIcon = t.defaultIconKey;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.assetIconLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in assetIconKeys)
                      InkWell(
                        onTap: () => setState(() {
                          selectedIcon = key;
                          iconTouched = true;
                        }),
                        borderRadius: BorderRadius.circular(24),
                        child: CircleAvatar(
                          backgroundColor: selectedIcon == key
                              ? AppColors.gold
                              : AppColors.inkSurfaceAlt,
                          child: Icon(
                            iconForAssetKey(key),
                            size: 20,
                            color: selectedIcon == key
                                ? AppColors.inkBackground
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              if (!isMain && !formKey.currentState!.validate()) return;
              Navigator.of(context).pop(
                _AssetFormResult(
                  isMain ? (initial?.name ?? '') : controller.text.trim(),
                  selectedIcon,
                  selectedType,
                ),
              );
            },
            child: Text(initial == null ? l10n.actionAdd : l10n.actionSave),
          ),
        ],
      ),
    ),
  );
}

class _AssetRow extends ConsumerWidget {
  const _AssetRow({
    required this.asset,
    required this.onEdit,
    this.onSetPrimary,
    this.onDelete,
    this.dragIndex,
    super.key,
  });

  final Asset asset;
  final VoidCallback onEdit;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onDelete;
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(assetBalanceProvider(asset.id));
    final balanceText = balanceAsync.maybeWhen(
      data: formatRupiah,
      orElse: () => '…',
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.inkSurfaceAlt,
        child: Icon(iconForAssetKey(asset.icon), color: AppColors.gold),
      ),
      title: Row(
        children: [
          Flexible(child: Text(assetDisplayName(asset, l10n))),
          if (asset.isPrimary) ...[
            const SizedBox(width: 8),
            _PrimaryBadge(label: l10n.assetPrimaryBadge),
          ],
        ],
      ),
      subtitle: Text('$balanceText · ${assetTypeLabel(asset.type, l10n)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              asset.isPrimary ? Icons.star_rounded : Icons.star_outline_rounded,
              color: asset.isPrimary ? AppColors.gold : null,
            ),
            tooltip: l10n.assetSetPrimaryAction,
            onPressed: onSetPrimary,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: l10n.assetEditTitle,
            onPressed: onEdit,
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.actionDelete,
              onPressed: onDelete,
            ),
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex!,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.drag_handle_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lencana kecil "Utama" di sebelah nama aset ber‑`isPrimary`.
class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
