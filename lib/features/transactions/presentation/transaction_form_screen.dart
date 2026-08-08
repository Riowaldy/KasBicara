import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/id_generator.dart';
import '../../../core/voice_parser.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/category_icons.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
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
                    'Hasil pengenalan suara',
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
    return SegmentedButton<TransactionType>(
      key: const Key('type-toggle'),
      segments: const [
        ButtonSegment(
          value: TransactionType.keluar,
          label: Text('Keluar'),
          icon: Icon(Icons.arrow_upward_rounded),
        ),
        ButtonSegment(
          value: TransactionType.masuk,
          label: Text('Masuk'),
          icon: Icon(Icons.arrow_downward_rounded),
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
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: _type == TransactionType.masuk
            ? AppColors.income.withValues(alpha: 0.25)
            : AppColors.expense.withValues(alpha: 0.25),
        selectedForegroundColor: _type == TransactionType.masuk
            ? AppColors.income
            : AppColors.expense,
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      key: const Key('amount-field'),
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [RupiahInputFormatter()],
      autofocus: _amountNeedsAttention,
      decoration: InputDecoration(
        labelText: 'Jumlah',
        prefixText: 'Rp ',
        helperText: _amountNeedsAttention
            ? 'Tidak terdeteksi dari suara, isi manual'
            : null,
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
          return 'Jumlah harus lebih dari 0';
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
        decoration: const InputDecoration(labelText: 'Tanggal'),
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
          decoration: const InputDecoration(labelText: 'Kategori'),
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
          validator: (value) => value == null ? 'Pilih kategori' : null,
        );
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      key: const Key('note-field'),
      controller: _noteController,
      decoration: const InputDecoration(labelText: 'Keterangan (opsional)'),
      maxLines: 2,
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Batal'),
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
                : const Text('Simpan'),
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
