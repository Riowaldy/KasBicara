import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/transaction_type.dart';
import 'export_data.dart';

// Warna brand KasBicara untuk aksen laporan — palet PDF terpisah dari
// AppColors (Flutter Color) karena package `pdf` punya tipe warna sendiri.
// Latar tetap putih (konvensi dokumen cetak), bukan navy gelap seperti UI app.
const _pdfNavy = PdfColor.fromInt(0xFF0B1E3D);
const _pdfGold = PdfColor.fromInt(0xFFC79A4E);
const _pdfIncome = PdfColor.fromInt(0xFF2E7D4F);
const _pdfExpense = PdfColor.fromInt(0xFFB4442C);
const _pdfMuted = PdfColor.fromInt(0xFF6B6B6B);

/// Bangun file PDF: ringkasan total + tabel transaksi (PRD §6.7), sesuai
/// filter periode/kategori aktif.
Future<Uint8List> buildPdfBytes(ExportData data) async {
  final doc = pw.Document();
  final now = DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'KasBicara - Laporan Transaksi',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _pdfNavy,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Periode: ${data.periodLabel}',
            style: pw.TextStyle(fontSize: 11, color: _pdfMuted),
          ),
          pw.Text(
            'Dibuat: ${date_utils.dateLabel(now)}',
            style: pw.TextStyle(fontSize: 9, color: _pdfMuted),
          ),
          pw.Divider(color: _pdfGold, thickness: 1.5),
        ],
      ),
      build: (context) => [
        _buildSummaryTable(data),
        pw.SizedBox(height: 20),
        pw.Text(
          'Rincian Transaksi (${data.transactions.length})',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _buildTransactionsTable(data),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _buildSummaryTable(ExportData data) {
  pw.Widget row(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _pdfMuted, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      children: [
        row(
          'Total Pemasukan',
          formatRupiah(data.totalIncome),
          color: _pdfIncome,
        ),
        row(
          'Total Pengeluaran',
          formatRupiah(data.totalExpense),
          color: _pdfExpense,
        ),
        pw.Divider(height: 10),
        row(
          'Selisih',
          formatRupiah(data.balance),
          color: data.balance >= 0 ? _pdfIncome : _pdfExpense,
        ),
      ],
    ),
  );
}

pw.Widget _buildTransactionsTable(ExportData data) {
  if (data.transactions.isEmpty) {
    return pw.Text(
      'Tidak ada transaksi pada periode ini.',
      style: pw.TextStyle(fontSize: 10, color: _pdfMuted),
    );
  }

  return pw.TableHelper.fromTextArray(
    headers: ['Tanggal', 'Tipe', 'Kategori', 'Keterangan', 'Jumlah'],
    headerStyle: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    ),
    headerDecoration: const pw.BoxDecoration(color: _pdfNavy),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellAlignments: const {4: pw.Alignment.centerRight},
    headerAlignments: const {4: pw.Alignment.centerRight},
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    data: data.transactions.map((t) {
      final isIncome = t.type == TransactionType.masuk;
      return [
        date_utils.toDateString(t.date),
        isIncome ? 'Masuk' : 'Keluar',
        data.categoryNameFor(t),
        t.note ?? '-',
        '${isIncome ? '+' : '-'}${formatRupiah(t.amount)}',
      ];
    }).toList(),
  );
}
