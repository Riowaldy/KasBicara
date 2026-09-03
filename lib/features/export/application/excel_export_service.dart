import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/transaction_type.dart';
import 'export_data.dart';

const _sheetTransaksi = 'Transaksi';
const _sheetRingkasan = 'Ringkasan';

/// Bangun file .xlsx: sheet "Transaksi" (tanggal, tipe, kategori,
/// keterangan, jumlah) + sheet "Ringkasan" (PRD §6.7). Fungsi murni Dart —
/// tidak butuh platform channel, sehingga bisa diuji langsung.
Uint8List buildExcelBytes(ExportData data) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != _sheetTransaksi) {
    excel.rename(defaultSheet, _sheetTransaksi);
  }

  excel.appendRow(_sheetTransaksi, [
    TextCellValue('Tanggal'),
    TextCellValue('Tipe'),
    TextCellValue('Pocket'),
    TextCellValue('Kategori'),
    TextCellValue('Keterangan'),
    TextCellValue('Jumlah'),
  ]);

  for (final t in data.transactions) {
    excel.appendRow(_sheetTransaksi, [
      TextCellValue(date_utils.toDateString(t.date)),
      TextCellValue(t.type == TransactionType.masuk ? 'Masuk' : 'Keluar'),
      TextCellValue(data.pocketNameFor(t)),
      TextCellValue(data.categoryNameFor(t)),
      TextCellValue(t.note ?? ''),
      DoubleCellValue(t.amount.toDouble()),
    ]);
  }

  excel.appendRow(_sheetRingkasan, [
    TextCellValue('Periode'),
    TextCellValue(data.periodLabel),
  ]);
  excel.appendRow(_sheetRingkasan, [
    TextCellValue('Jumlah Transaksi'),
    IntCellValue(data.transactions.length),
  ]);
  excel.appendRow(_sheetRingkasan, [
    TextCellValue('Total Pemasukan'),
    DoubleCellValue(data.totalIncome.toDouble()),
  ]);
  excel.appendRow(_sheetRingkasan, [
    TextCellValue('Total Pengeluaran'),
    DoubleCellValue(data.totalExpense.toDouble()),
  ]);
  excel.appendRow(_sheetRingkasan, [
    TextCellValue('Selisih'),
    DoubleCellValue(data.balance.toDouble()),
  ]);

  final bytes = excel.save();
  if (bytes == null) {
    throw StateError('Gagal membuat file Excel');
  }
  return Uint8List.fromList(bytes);
}
