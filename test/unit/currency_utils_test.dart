import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/utils/currency_utils.dart';

void main() {
  group('formatCompactRupiah', () {
    test('di bawah seribu tampil apa adanya', () {
      expect(formatCompactRupiah(500), '500');
    });

    test('ribuan dibulatkan dengan sufiks "rb"', () {
      expect(formatCompactRupiah(50000), '50rb');
      expect(formatCompactRupiah(500000), '500rb');
    });

    test('jutaan dengan sufiks "jt", termasuk desimal satu digit', () {
      expect(formatCompactRupiah(2000000), '2jt');
      expect(formatCompactRupiah(1500000), '1,5jt');
    });

    test('nilai negatif mempertahankan tanda minus', () {
      expect(formatCompactRupiah(-50000), '-50rb');
    });

    test('nol tampil sebagai "0"', () {
      expect(formatCompactRupiah(0), '0');
    });
  });

  group('groupThousands', () {
    test('mengelompokkan ribuan dengan titik', () {
      expect(groupThousands(50000), '50.000');
      expect(groupThousands(2500000), '2.500.000');
      expect(groupThousands(500), '500');
    });
  });
}
