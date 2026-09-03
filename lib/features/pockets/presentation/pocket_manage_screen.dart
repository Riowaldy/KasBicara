import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../data/models/pocket_model.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/pocket_icons.dart';
import '../../../shared/widgets/pocket_selector.dart';

/// Layar "Kelola Pocket" (konsep "Pocket KasBicara" §06): daftar pocket +
/// saldo, tambah/ubah/hapus, dan susun ulang. Pocket Utama terkunci di
/// posisi teratas dan tidak dapat dihapus.
class PocketManageScreen extends ConsumerWidget {
  const PocketManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pocketsAsync = ref.watch(pocketsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pocketManageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPocket(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.pocketAddTitle),
      ),
      body: pocketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat pocket: $e')),
        data: (pockets) {
          final main = pockets.firstWhere(
            (p) => p.isDefault,
            orElse: () => const Pocket(
              id: kMainPocketId,
              name: 'Pocket Utama',
              icon: 'wallet',
              isDefault: true,
              sortOrder: 0,
            ),
          );
          final others = pockets.where((p) => !p.isDefault).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  l10n.pocketManageHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _PocketRow(
                pocket: main,
                onEdit: () => _editPocket(context, ref, main),
              ),
              const Divider(height: 1),
              if (others.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    l10n.pocketEmpty,
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
                    final pocket = others[index];
                    return _PocketRow(
                      key: ValueKey(pocket.id),
                      pocket: pocket,
                      dragIndex: index,
                      onEdit: () => _editPocket(context, ref, pocket),
                      onDelete: () => _deletePocket(context, ref, pocket),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addPocket(BuildContext context, WidgetRef ref) async {
    final result = await _showPocketForm(context);
    if (result == null) return;
    final repo = await ref.read(pocketRepositoryProvider.future);
    final maxSort = (ref.read(pocketsStreamProvider).valueOrNull ?? [])
        .fold<int>(0, (m, p) => p.sortOrder > m ? p.sortOrder : m);
    await repo.create(
      Pocket(
        id: generateId(),
        name: result.name,
        icon: result.icon,
        isDefault: false,
        sortOrder: maxSort + 1,
      ),
    );
  }

  Future<void> _editPocket(
    BuildContext context,
    WidgetRef ref,
    Pocket pocket,
  ) async {
    final result = await _showPocketForm(context, initial: pocket);
    if (result == null) return;
    final repo = await ref.read(pocketRepositoryProvider.future);
    await repo.update(
      pocket.copyWith(
        // Nama Pocket Utama tidak dapat diubah (dirender dari l10n).
        name: pocket.isDefault ? null : result.name,
        icon: result.icon,
      ),
    );
  }

  Future<void> _deletePocket(
    BuildContext context,
    WidgetRef ref,
    Pocket pocket,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final txCount = (ref.read(transactionsStreamProvider).valueOrNull ?? [])
        .where((t) => t.pocketId == pocket.id)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pocketDeleteConfirmTitle),
        content: Text(
          txCount == 0
              ? l10n.pocketDeleteConfirmEmpty(pocket.name)
              : l10n.pocketDeleteConfirmReassign(txCount, pocket.name),
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
      await txRepo.reassignPocket(
        fromPocketId: pocket.id,
        toPocketId: kMainPocketId,
      );
    }
    final repo = await ref.read(pocketRepositoryProvider.future);
    await repo.delete(pocket.id);

    // Kalau pocket yang dihapus sedang aktif, kembali ke "Semua Pocket".
    if (ref.read(activePocketProvider) == pocket.id) {
      ref.read(activePocketProvider.notifier).state = null;
    }
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<Pocket> others,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = [...others];
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final repo = await ref.read(pocketRepositoryProvider.future);
    for (var i = 0; i < reordered.length; i++) {
      final desiredSort = i + 1; // Pocket Utama menempati 0.
      if (reordered[i].sortOrder != desiredSort) {
        await repo.update(reordered[i].copyWith(sortOrder: desiredSort));
      }
    }
  }
}

/// Hasil form pocket (nama + kunci ikon).
class _PocketFormResult {
  const _PocketFormResult(this.name, this.icon);
  final String name;
  final String icon;
}

Future<_PocketFormResult?> _showPocketForm(
  BuildContext context, {
  Pocket? initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial?.name ?? '');
  final formKey = GlobalKey<FormState>();
  var selectedIcon = initial?.icon ?? pocketIconKeys.first;
  final isMain = initial?.isDefault ?? false;

  return showDialog<_PocketFormResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          initial == null ? l10n.pocketAddTitle : l10n.pocketEditTitle,
        ),
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
                    decoration: InputDecoration(
                      labelText: l10n.pocketNameLabel,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.pocketNameError
                        : null,
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.pocketIconLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in pocketIconKeys)
                      InkWell(
                        onTap: () => setState(() => selectedIcon = key),
                        borderRadius: BorderRadius.circular(24),
                        child: CircleAvatar(
                          backgroundColor: selectedIcon == key
                              ? AppColors.gold
                              : AppColors.inkSurfaceAlt,
                          child: Icon(
                            iconForPocketKey(key),
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
                _PocketFormResult(
                  isMain ? (initial?.name ?? '') : controller.text.trim(),
                  selectedIcon,
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

class _PocketRow extends ConsumerWidget {
  const _PocketRow({
    required this.pocket,
    required this.onEdit,
    this.onDelete,
    this.dragIndex,
    super.key,
  });

  final Pocket pocket;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(pocketBalanceProvider(pocket.id));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.inkSurfaceAlt,
        child: Icon(iconForPocketKey(pocket.icon), color: AppColors.gold),
      ),
      title: Text(pocketDisplayName(pocket, l10n)),
      subtitle: Text(
        balanceAsync.maybeWhen(data: formatRupiah, orElse: () => '…'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: l10n.pocketEditTitle,
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
