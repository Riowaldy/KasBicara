import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/category_model.dart';
import 'package:kasbicara/data/models/pocket_model.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';
import 'package:kasbicara/features/export/application/excel_export_service.dart';
import 'package:kasbicara/features/export/application/export_data.dart';

/// `excel` merepresentasikan angka bulat sebagai [IntCellValue] setelah
/// round-trip save/decode meski ditulis sebagai [DoubleCellValue] — baca
/// keduanya secara fleksibel di sini.
num _numValue(CellValue? value) {
  return switch (value) {
    IntCellValue v => v.value,
    DoubleCellValue v => v.value,
    _ => throw ArgumentError('Bukan cell numerik: $value'),
  };
}

void main() {
  const makanan = Category(
    id: 'expense-makanan-minuman',
    name: 'Makanan & Minuman',
    type: TransactionType.keluar,
    icon: 'food',
    isDefault: true,
  );
  const gaji = Category(
    id: 'income-gaji',
    name: 'Gaji',
    type: TransactionType.masuk,
    icon: 'salary',
    isDefault: true,
  );

  ExportData buildData() {
    final date = DateTime(2026, 8, 8);
    return ExportData(
      transactions: [
        Transaction(
          id: 't1',
          type: TransactionType.keluar,
          amount: 50000,
          category: 'expense-makanan-minuman',
          note: 'Makan siang',
          date: date,
          createdAt: date,
          updatedAt: date,
        ),
        Transaction(
          id: 't2',
          type: TransactionType.masuk,
          amount: 2000000,
          category: 'income-gaji',
          date: date,
          createdAt: date,
          updatedAt: date,
        ),
      ],
      categoriesById: {'expense-makanan-minuman': makanan, 'income-gaji': gaji},
      pocketNamesById: const {kMainPocketId: 'Pocket Utama'},
      periodLabel: 'Agustus 2026',
    );
  }

  test('menghasilkan sheet Transaksi & Ringkasan yang bisa dibaca ulang', () {
    final bytes = buildExcelBytes(buildData());
    final decoded = Excel.decodeBytes(bytes);

    expect(decoded.sheets.keys, containsAll(['Transaksi', 'Ringkasan']));

    final transaksiRows = decoded['Transaksi'].rows;
    // header + 2 transaksi
    expect(transaksiRows.length, 3);
    expect(transaksiRows[0].map((c) => c?.value.toString()).toList(), [
      'Tanggal',
      'Tipe',
      'Pocket',
      'Kategori',
      'Keterangan',
      'Jumlah',
    ]);
    expect(transaksiRows[1][0]?.value.toString(), '2026-08-08');
    expect(transaksiRows[1][1]?.value.toString(), 'Keluar');
    expect(transaksiRows[1][2]?.value.toString(), 'Pocket Utama');
    expect(transaksiRows[1][3]?.value.toString(), 'Makanan & Minuman');
    expect(transaksiRows[1][4]?.value.toString(), 'Makan siang');
    expect(_numValue(transaksiRows[1][5]?.value), 50000);

    expect(transaksiRows[2][1]?.value.toString(), 'Masuk');
    expect(transaksiRows[2][4]?.value.toString(), '');
  });

  test('sheet Ringkasan berisi total & selisih yang benar', () {
    final bytes = buildExcelBytes(buildData());
    final decoded = Excel.decodeBytes(bytes);
    final ringkasanRows = decoded['Ringkasan'].rows;

    CellValue? valueFor(String label) {
      final row = ringkasanRows.firstWhere(
        (r) => r[0]?.value.toString() == label,
      );
      return row[1]?.value;
    }

    expect(_numValue(valueFor('Total Pemasukan')), 2000000);
    expect(_numValue(valueFor('Total Pengeluaran')), 50000);
    expect(_numValue(valueFor('Selisih')), 1950000);
    expect(_numValue(valueFor('Jumlah Transaksi')), 2);
    expect(valueFor('Periode').toString(), 'Agustus 2026');
  });

  test('daftar transaksi kosong tetap menghasilkan file valid', () {
    final data = ExportData(
      transactions: const [],
      categoriesById: const {},
      periodLabel: 'September 2026',
    );
    final bytes = buildExcelBytes(data);
    final decoded = Excel.decodeBytes(bytes);

    // hanya baris header yang tersisa
    expect(decoded['Transaksi'].rows.length, 1);
  });
}
