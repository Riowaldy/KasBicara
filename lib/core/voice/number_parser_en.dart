// Parser angka Bahasa Inggris. Struktur berbeda dari id/ms: "fifty thousand",
// "two hundred", kata sambung "and"/"a" (konsep "Trilingual KasBicara" §02, §06).

/// Kata pengisi di sekitar angka (en) yang dilewati saat parsing.
const enAmountFillerWords = {
  'and',
  'a',
  'of',
  'rp',
  'rupiah',
  'rm',
  'ringgit',
  'dollar',
  'dollars',
  'bucks',
};

const _units = {
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

const _scales = {
  'thousand': 1000,
  'k': 1000,
  'million': 1000000,
  'billion': 1000000000,
};

bool isEnNumberToken(String tok) {
  return RegExp(r'^\d+$').hasMatch(tok) ||
      _units.containsKey(tok) ||
      _scales.containsKey(tok) ||
      tok == 'hundred' ||
      enAmountFillerWords.contains(tok);
}

/// Pisahkan singkatan skala yang menempel ke digit, mis. "50k" -> "50 k".
String normalizeEnNumericGlue(String text) {
  return text.replaceAllMapped(
    RegExp(r'(\d+)(k)\b'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
}

/// Konversi rangkaian token angka Inggris menjadi int, atau null bila ada
/// token tak dikenal (parser mundur alih-alih menebak).
int? parseEnAmount(List<String> tokens) {
  var total = 0;
  var current = 0;
  var any = false;

  for (final tok in tokens) {
    if (enAmountFillerWords.contains(tok)) continue;

    if (RegExp(r'^\d+$').hasMatch(tok)) {
      current += int.parse(tok);
      any = true;
    } else if (_units.containsKey(tok)) {
      current += _units[tok]!;
      any = true;
    } else if (tok == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
      any = true;
    } else if (_scales.containsKey(tok)) {
      total += (current == 0 ? 1 : current) * _scales[tok]!;
      current = 0;
      any = true;
    } else {
      return null;
    }
  }

  return any ? total + current : null;
}
