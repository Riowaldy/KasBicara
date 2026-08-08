import 'package:intl/intl.dart';

final _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

/// Format [amount] (integer Rupiah) menjadi string mis. "Rp50.000".
String formatRupiah(int amount) => _rupiahFormat.format(amount);

/// Kebalikan dari [formatRupiah] / input pengguna: buang semua karakter
/// selain digit, kembalikan `null` jika hasilnya kosong.
int? parseRupiahDigits(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.parse(digits);
}

/// Kelompokkan digit [amount] dengan pemisah ribuan "." tanpa simbol mata
/// uang (mis. 50000 -> "50.000"). Dipakai field input & prefill form.
String groupThousands(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}
