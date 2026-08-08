import 'package:flutter/material.dart';

import '../../features/export/application/export_controller.dart';

/// Bottom sheet pemilihan format ekspor — dipakai bersama oleh Riwayat &
/// Dashboard (PRD §6.7, Flow B). Null jika pengguna membatalkan.
Future<ExportFormat?> showExportFormatSheet(BuildContext context) {
  return showModalBottomSheet<ExportFormat>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Export Excel (.xlsx)'),
              onTap: () => Navigator.of(context).pop(ExportFormat.excel),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Export PDF'),
              onTap: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),
          ],
        ),
      );
    },
  );
}
