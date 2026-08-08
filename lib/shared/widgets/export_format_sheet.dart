import 'package:flutter/material.dart';

import '../../features/export/application/export_controller.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet pemilihan format ekspor — dipakai bersama oleh Riwayat &
/// Dashboard (PRD §6.7, Flow B). Null jika pengguna membatalkan.
Future<ExportFormat?> showExportFormatSheet(BuildContext context) {
  return showModalBottomSheet<ExportFormat>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: Text(l10n.exportExcel),
              onTap: () => Navigator.of(context).pop(ExportFormat.excel),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: Text(l10n.exportPdf),
              onTap: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),
          ],
        ),
      );
    },
  );
}
