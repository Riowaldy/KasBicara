import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Membagikan file .xlsx lewat share sheet OS (PRD §6.7).
/// [filenameBase] tanpa ekstensi, mis. "kasbicara-agustus-2026".
Future<void> shareExcel(Uint8List bytes, String filenameBase) async {
  final filename = '$filenameBase.xlsx';
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: filename,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: [filename],
      subject: 'Laporan Transaksi KasBicara',
    ),
  );
}

/// Membagikan file PDF lewat share sheet OS.
Future<void> sharePdf(Uint8List bytes, String filenameBase) async {
  await Printing.sharePdf(bytes: bytes, filename: '$filenameBase.pdf');
}
