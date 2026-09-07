import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/features/scan/application/receipt_layout.dart';

TextFragment frag(String text, double top, double left, {double height = 20}) =>
    TextFragment(text: text, top: top, bottom: top + height, left: left);

void main() {
  test(
    'gabung potongan sebaris (label kiri + nominal kanan) jadi satu baris',
    () {
      final text = assembleReceiptText([
        frag('55.745', 100, 300),
        frag('Total', 102, 10),
        frag('Bayar', 142, 10),
        frag('100.000', 140, 300),
      ]);

      expect(text, 'Total  55.745\nBayar  100.000');
    },
  );

  test('urutan baris mengikuti posisi vertikal, bukan urutan masukan', () {
    final text = assembleReceiptText([
      frag('C', 300, 0),
      frag('A', 100, 0),
      frag('B', 200, 0),
    ]);

    expect(text, 'A\nB\nC');
  });

  test(
    'toleran kemiringan: baris kiri & kanan sedikit bergeser tetap menyatu',
    () {
      // Kanan turun 8px dari kiri (struk miring) — tumpang tindih masih > 30%.
      final text = assembleReceiptText([
        frag('Kembali', 100, 10),
        frag('44.255', 108, 320),
      ]);

      expect(text, 'Kembali  44.255');
    },
  );

  test('baris berbeda (tanpa tumpang tindih) tidak digabung', () {
    final text = assembleReceiptText([
      frag('baris satu', 100, 10, height: 18),
      frag('baris dua', 122, 10, height: 18),
    ]);

    expect(text, 'baris satu\nbaris dua');
  });

  test('masukan kosong menghasilkan string kosong', () {
    expect(assembleReceiptText([]), '');
    expect(assembleReceiptText([frag('   ', 0, 0)]), '');
  });
}
