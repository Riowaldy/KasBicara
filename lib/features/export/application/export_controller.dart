import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import 'excel_export_service.dart';
import 'export_data.dart';
import 'export_share_service.dart';
import 'pdf_export_service.dart';

enum ExportFormat { excel, pdf }

/// Bangun file laporan (Excel/PDF) dari [transactions] yang SUDAH difilter
/// oleh pemanggil, lalu tampilkan share sheet OS (PRD §6.7, Flow B).
Future<void> exportTransactions({
  required BuildContext context,
  required WidgetRef ref,
  required List<Transaction> transactions,
  required String periodLabel,
  required ExportFormat format,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;

  if (transactions.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportEmptyWarning)));
    return;
  }

  try {
    final categories = await ref.read(categoriesProvider.future);
    final categoriesById = {for (final c in categories) c.id: c};
    final data = ExportData(
      transactions: transactions,
      categoriesById: categoriesById,
      periodLabel: periodLabel,
    );
    final filenameBase = 'kasbicara-${_slugify(periodLabel)}';

    switch (format) {
      case ExportFormat.excel:
        await shareExcel(buildExcelBytes(data), filenameBase);
      case ExportFormat.pdf:
        await sharePdf(await buildPdfBytes(data), filenameBase);
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Gagal mengekspor: $e')));
  }
}

String _slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
