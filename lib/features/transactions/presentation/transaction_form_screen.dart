import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/id_generator.dart';
import '../../../core/voice/voice_parser.dart';
import '../../../data/models/pocket_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/pocket_icons.dart';
import '../../../shared/widgets/pocket_selector.dart';
import '../../../shared/widgets/rupiah_input_formatter.dart';

/// Kartu konfirmasi/edit transaksi (PRD §6.2 & §6.3).
///
/// Dipakai untuk tiga alur: tambah manual (keduanya null), edit transaksi
/// tersimpan ([initial] terisi), dan konfirmasi hasil suara ([voiceDraft]
/// terisi, Fase 3) — [initial] dan [voiceDraft] tidak pernah diisi bersamaan.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.initial, this.voiceDraft})
    : assert(
        initial == null || voiceDraft == null,
        'initial (edit) dan voiceDraft (tambah via suara) tidak boleh bersamaan',
      );

  final Transaction? initial;
  final VoiceParseResult? voiceDraft;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _type;
  late DateTime _date;
  String? _categoryId;
  late String _pocketId;
  bool _saving = false;

  /// True jika amount berasal dari draft suara yang TIDAK yakin — field
  /// dibiarkan kosong & diberi highlight lembut (PRD §12), bukan ditebak.
  bool _amountNeedsAttention = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final draft = widget.voiceDraft;

    _type = initial?.type ?? draft?.type ?? TransactionType.keluar;
    _date = date_utils.dateOnly(initial?.date ?? DateTime.now());
    _categoryId = initial?.category ?? draft?.category;
    // Nilai awal pocket (konsep "Pocket KasBicara" §06): transaksi lama pakai
    // pocket‑nya; selain itu ikut pocket aktif, atau Pocket Utama saat
    // konteks "Semua Pocket". Deteksi pocket dari suara = Fase 2.
    _pocketId =
        initial?.pocketId ?? ref.read(activePocketProvider) ?? kMainPocketId;
    _noteController = TextEditingController(
      text: initial?.note ?? draft?.note ?? '',
    );

    if (initial != null) {
      _amountController = TextEditingController(
        text: groupThousands(initial.amount),
      );
    } else if (draft != null && draft.amountConfident && draft.amount != null) {
      _amountController = TextEditingController(
        text: groupThousands(draft.amount!),
      );
    } else {
      _amountController = TextEditingController();
      _amountNeedsAttention = draft != null; // ada draft tapi jumlah tak yakin
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.formEditTitle : l10n.formAddTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.voiceDraft != null) ...[
                _buildVoiceReferenceCard(widget.voiceDraft!),
                const SizedBox(height: 20),
              ],
              _buildTypeToggle(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 16),
              _buildPocketField(),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 32),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceReferenceCard(VoiceParseResult draft) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mic_rounded, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.formVoiceReferenceTitle,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${draft.rawTranscript}"',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<TransactionType>(
      key: const Key('type-toggle'),
      segments: [
        ButtonSegment(
          value: TransactionType.keluar,
          label: Text(l10n.formTypeOut),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
        ButtonSegment(
          value: TransactionType.masuk,
          label: Text(l10n.formTypeIn),
          icon: const Icon(Icons.arrow_downward_rounded),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (selection) {
        setState(() {
          _type = selection.first;
          // Kategori lama mungkin tidak berlaku untuk jenis baru.
          _categoryId = null;
        });
      },
      // Latar SOLID (bukan tint transparan) + teks navy: tint 25% di atas
      // income/expense hanya ~3:1, di bawah ambang teks WCAG AA 4.5:1.
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: _type == TransactionType.masuk
            ? AppColors.incomeText
            : AppColors.expenseText,
        selectedForegroundColor: AppColors.inkBackground,
      ),
    );
  }

  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      key: const Key('amount-field'),
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [RupiahInputFormatter()],
      autofocus: _amountNeedsAttention,
      decoration: InputDecoration(
        labelText: l10n.formAmountLabel,
        prefixText: 'Rp ',
        helperText: _amountNeedsAttention ? l10n.formAmountHelperVoice : null,
        helperStyle: const TextStyle(color: AppColors.gold),
        enabledBorder: _amountNeedsAttention
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
              )
            : null,
      ),
      onChanged: (_) {
        if (_amountNeedsAttention) {
          setState(() => _amountNeedsAttention = false);
        }
      },
      validator: (value) {
        final amount = parseRupiahDigits(value ?? '');
        if (amount == null || amount <= 0) {
          return l10n.formAmountError;
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      key: const Key('date-field'),
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.formDateLabel,
        ),
        child: Text(date_utils.toDateString(_date)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = date_utils.dateOnly(picked));
    }
  }

  Widget _buildCategoryField() {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_type));

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Gagal memuat kategori: $error'),
      data: (categories) {
        final validIds = categories.map((c) => c.id).toSet();
        if (_categoryId != null && !validIds.contains(_categoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _categoryId = null);
          });
        }

        return DropdownButtonFormField<String>(
          key: const Key('category-dropdown'),
          initialValue: validIds.contains(_categoryId) ? _categoryId : null,
          decoration: InputDecoration(labelText: l10n.formCategoryLabel),
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconForCategoryKey(c.icon), size: 18),
                      const SizedBox(width: 8),
                      Text(c.name),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _categoryId = value),
          validator: (value) => value == null ? l10n.formCategoryError : null,
        );
      },
    );
  }

  Widget _buildPocketField() {
    final l10n = AppLocalizations.of(context)!;
    final pocketsAsync = ref.watch(pocketsStreamProvider);

    return pocketsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Gagal memuat pocket: $error'),
      data: (pockets) {
        final validIds = pockets.map((p) => p.id).toSet();
        final value = validIds.contains(_pocketId)
            ? _pocketId
            : (validIds.contains(kMainPocketId)
                  ? kMainPocketId
                  : (pockets.isNotEmpty ? pockets.first.id : null));

        return DropdownButtonFormField<String>(
          key: const Key('pocket-dropdown'),
          initialValue: value,
          decoration: InputDecoration(labelText: l10n.formPocketLabel),
          items: pockets
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconForPocketKey(p.icon), size: 18),
                      const SizedBox(width: 8),
                      Text(pocketDisplayName(p, l10n)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() {
            if (v != null) _pocketId = v;
          }),
          validator: (v) => v == null ? l10n.formPocketError : null,
        );
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      key: const Key('note-field'),
      controller: _noteController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.formNoteLabel,
      ),
      maxLines: 2,
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            key: const Key('save-button'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.actionSave),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final amount = parseRupiahDigits(_amountController.text)!;
      final now = DateTime.now();
      final repo = await ref.read(transactionRepositoryProvider.future);

      if (_isEditing) {
        final updated = widget.initial!.copyWith(
          type: _type,
          amount: amount,
          category: _categoryId,
          pocketId: _pocketId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          date: _date,
          updatedAt: now,
        );
        await repo.update(updated);
      } else {
        final created = Transaction(
          id: generateId(),
          type: _type,
          amount: amount,
          category: _categoryId!,
          pocketId: _pocketId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          date: _date,
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(created);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
