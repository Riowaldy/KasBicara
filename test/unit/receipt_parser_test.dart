import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/transaction_type.dart';
import 'package:kasbicara/features/scan/application/receipt_parser.dart';

void main() {
  test('struk khas Indonesia: ambil GRAND TOTAL, tanggal, dan nama toko', () {
    const text = '''
INDOMARET
JL. MERDEKA NO. 10
NPWP 01.234.567.8-999.000

Roti Tawar          14.500
Susu UHT 1L         18.000
Kopi Sachet x3       6.000

SUBTOTAL            38.500
DISKON              1.500
GRAND TOTAL        37.000
TUNAI              50.000
KEMBALI            13.000

12/03/2026 14:22
Terima kasih
''';

    final r = parseReceiptText(text);

    expect(r.amount, 37000);
    expect(r.amountConfident, isTrue);
    expect(r.type, TransactionType.keluar);
    expect(r.date, DateTime(2026, 3, 12));
    expect(r.merchant, 'INDOMARET');
  });

  test('tanpa baris total: tebak angka berpemisah terbesar, belum yakin', () {
    const text = '''
Warung Bu Sri
Nasi + Ayam    25.000
Es Teh          5.000
''';

    final r = parseReceiptText(text);

    expect(r.amount, 25000);
    expect(r.amountConfident, isFalse);
    expect(r.merchant, 'Warung Bu Sri');
  });

  test('nominal dengan sen dan pemisah gaya en: 1,234,567.00 -> 1234567', () {
    final r = parseReceiptText('TOTAL  1,234,567.00');
    expect(r.amount, 1234567);
    expect(r.amountConfident, isTrue);
  });

  test('abaikan baris kembalian meski nilainya besar', () {
    const text = '''
TOTAL       30.000
TUNAI      100.000
KEMBALIAN   70.000
''';
    final r = parseReceiptText(text);
    expect(r.amount, 30000);
  });

  test('tanggal tidak valid diabaikan (31/02), format ISO diterima', () {
    expect(parseReceiptText('tgl 31/02/2026').date, isNull);
    expect(parseReceiptText('2026-02-15').date, DateTime(2026, 2, 15));
  });

  test('teks kosong / tak terbaca menghasilkan hasil kosong', () {
    final r = parseReceiptText('   \n  \n');
    expect(r.isEmpty, isTrue);
    expect(r.amount, isNull);
    expect(r.date, isNull);
  });
}
