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

  test(
    'struk kolom terpisah (OCR pisah label & angka): total dari nilai berulang',
    () {
      // Meniru hasil ML Kit pada struk thermal: kolom kiri (label) dan kolom
      // kanan (angka) terbaca sebagai dua blok terpisah.
      const text = '''
Berkaa Shop
Jl. Medayu Utara 50, Surabaya
81529620220414142434
2022-04-14
14:24:34
No.0-24
Nasi Ayam Geprek
1 X 12.000
Rp 12.000
Nasi Ayam Kremes
1 X 15.000
Rp 15.000
Nasi Goreng Spesial
1 X 20.000
Rp 20.000
Sub Total
Total
Bayar (Cash)
Kembali
47.000
47.000
47.000
0
Link Kritik dan Saran:
''';

      final r = parseReceiptText(text);

      expect(r.amount, 47000);
      expect(r.amountConfident, isTrue);
      expect(r.date, DateTime(2022, 4, 14));
      expect(r.merchant, 'Berkaa Shop');
    },
  );

  test(
    'teks OCR asli (Berkaa Shop): kolom acak-acakan, total tetap 47.000',
    () {
      // Persis keluaran ML Kit dari struk pengguna: label & angka jadi blok
      // terpisah, nama kasir menyusup di antaranya, kolom harga item mendahului
      // kolom total, dan ada baris URL berangka panjang.
      const text = '''
Berkaa Shop
J1. Medayu Utara 50, Surabaya
81529620220414142434
2022-04-14
14:24:34
No.0-24
Nasi Ayam Geprek
1X 12.000
Nasi Ayam Kremes
1X 15.000
Nasi Goreng Spesial
1X 20.000
Sub Total
Total
Bayar (Cash)
Kenbali
Afi
sheila
Rp 12.000
Rp 15.000
Rp 20.000
47.000
47.000
47.000
Link Kritik dan Saran:
olshopin.com/f/748488
0
''';

      final r = parseReceiptText(text);

      expect(r.amount, 47000);
      expect(r.amountConfident, isTrue);
      expect(r.merchant, 'Berkaa Shop');
      expect(r.date, DateTime(2022, 4, 14));
    },
  );

  test(
    'teks OCR asli (Alfamart): "4,50" hasil OCR diselamatkan jadi 4.500',
    () {
      // OCR menelan satu digit ("4.500" -> "4,50") dan menyebar kolomnya.
      // Total dipulihkan dari harga baris item "SARI ROTI ... 4,500 4,500".
      const text = '''
ALFAMART STA, KARET
PT, SUMBER ALFARIA TRIJAYA, TBK
LMH. THAMRIN NO. 9, CIKOKOL, TANGERANG
NPWP: 01.336.238.9-054.000
L, DUKUH PINGGIR, NO, 1, (ST TANAH ABAN
Bon KC79-805-19050MK8 Kasir : Tufti ac
SARI ROTI SH CK1 4,500 4,500
Total Item
Tunai
Kerbal ian
PPN
4
409)
4,50
5,000
500
Tgl. 19-05- 2017 06:51:42 V.2017.4.1
Kritik&Saraan: 1500959, SMS: O81111234
''';

      final r = parseReceiptText(text);

      expect(r.amount, 4500);
      expect(r.date, DateTime(2017, 5, 19));
    },
  );

  test(
    'teks OCR asli (Sarinah): jalur "Total" nyangkut, Σ harga item = 55.745',
    () {
      // Kolom "Total : / Bayar : / Kembali :" terpisah dari angkanya; jalur
      // kata kunci bisa nyangkut ke "Bayar" (100.000). Σ harga baris item
      // (2.500 + 6.545 + 46.700) mengoreksinya jadi 55.745.
      const text = '''
SARINAH Super Market
Jl. Kol Sugiono 18.
CV Surya Indah
Jen A Yani 125, Purworejo
NPWP:31.262.852.2-531.000
17.01.12 R005036 Trans No: 005121-N
TP SB TREND B
3581998-> 1 X 2,500 = 2,500
STELLA FINESE JMN 20
253171 -> 1 X 6,545 = 6,545
JC THE BEST KOMB
3490494-> 1 X 46,700 = 46,700
Total :
Total Barang :
Bayar :
Kembali :
55,745
3
100,000
44,255
Dasar PPn : 50,677
PPn : 5,068
** TERIMA KASIH **
''';

      final r = parseReceiptText(text);

      expect(r.amount, 55745);
    },
  );

  test(
    'alamat di-OCR "J1." (bukan "Jl.") tetap dilewati sebagai nama toko',
    () {
      const text = '''
Berkaa Shop
J1. Medayu Utara 50, Surabaya
81529620220414142434
Total 47.000
''';
      final r = parseReceiptText(text);
      expect(r.merchant, 'Berkaa Shop');
      expect(r.amount, 47000);
    },
  );

  test('OCR menghilangkan titik ribuan: "47000" bulat tetap terbaca', () {
    const text = '''
Kedai Kopi
Kopi Susu 15000
Roti Bakar 12000
TOTAL 47000
TUNAI 50000
KEMBALI 3000
''';
    final r = parseReceiptText(text);
    expect(r.amount, 47000);
    expect(r.amountConfident, isTrue);
  });

  test('barcode panjang tidak dianggap nominal', () {
    final r = parseReceiptText('81529620220414142434\nTotal 47.000');
    expect(r.amount, 47000);
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
