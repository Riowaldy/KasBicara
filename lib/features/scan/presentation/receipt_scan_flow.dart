import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/voice/voice_parser.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/receipt_parser.dart';

/// Alur "Pindai Struk": pilih sumber gambar → OCR di perangkat (ML Kit,
/// gratis & offline) → buka kartu transaksi ter-prefill untuk ditinjau.
///
/// Semua kegagalan (batal pilih, tak ada teks, error plugin) berujung mulus
/// ke input manual — struk hanya jalan pintas, bukan satu-satunya jalan
/// (mitigasi risiko PRD §13).
Future<void> startReceiptScan(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final source = await _pickSource(context);
  if (source == null || !context.mounted) return;

  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2400,
    );
  } catch (_) {
    if (context.mounted) _snack(context, l10n.scanFailed);
    return;
  }
  if (file == null || !context.mounted) return;

  _showProgress(context, l10n.scanProcessing);
  ReceiptScanResult? scan;
  try {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      scan = parseReceiptText(recognized.text);
    } finally {
      await recognizer.close();
    }
  } catch (_) {
    scan = null;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(); // tutup dialog progres

  if (scan == null) {
    _snack(context, l10n.scanFailed);
    return;
  }
  if (scan.isEmpty) {
    _snack(context, l10n.scanNoText);
  }

  final draft = VoiceParseResult(
    rawTranscript: (scan.merchant?.isNotEmpty ?? false)
        ? scan.merchant!
        : l10n.scanReceiptFallbackRef,
    type: scan.type,
    amount: scan.amount,
    amountConfident: scan.amountConfident,
    note: scan.merchant,
  );

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TransactionFormScreen(
        voiceDraft: draft,
        draftDate: scan!.date,
        draftSource: DraftSource.receipt,
      ),
    ),
  );
}

Future<ImageSource?> _pickSource(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(l10n.scanSourceCamera),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(l10n.scanSourceGallery),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

void _showProgress(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
