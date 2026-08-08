import 'package:flutter/services.dart';

import '../../core/utils/currency_utils.dart';

/// Format input jumlah secara live dengan pemisah ribuan (mis. "50.000")
/// sambil pengguna mengetik, tanpa mengganggu posisi kursor.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = groupThousands(int.parse(digitsOnly));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
