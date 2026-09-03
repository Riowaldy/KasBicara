// Parser angka Bahasa Indonesia & Bahasa Melayu — identik untuk keduanya
// (konsep "Trilingual KasBicara" §02). Dipakai bersama oleh `IdVoiceParser`
// dan `MsVoiceParser`. Bahasa Inggris memakai modul terpisah
// (`number_parser_en.dart`) karena struktur angkanya berbeda.

/// Kata pengisi di sekitar angka (id + ms) yang dilewati saat parsing.
const idMsAmountFillerWords = {
  'rp',
  'rupiah',
  'rm',
  'ringgit',
  'sen',
  'uang',
  'wang',
  'duit',
  'sebesar',
  'sejumlah',
  'senilai',
  'sekitar',
};

const _digitWords = {
  'nol': 0,
  'kosong': 0,
  'satu': 1,
  'dua': 2,
  'tiga': 3,
  'empat': 4,
  'lima': 5,
  'enam': 6,
  'tujuh': 7,
  'delapan': 8,
  'sembilan': 9,
};

const _fusedWords = {
  'sepuluh': 10,
  'sebelas': 11,
  'seratus': 100,
  'seribu': 1000,
  'sejuta': 1000000,
  'semiliar': 1000000000,
};

const _scaleWords = {
  'ribu': 1000,
  'rb': 1000,
  'k': 1000,
  'juta': 1000000,
  'jt': 1000000,
  'miliar': 1000000000,
  'milyar': 1000000000,
};

bool isIdMsNumberToken(String tok) {
  return RegExp(r'^\d+$').hasMatch(tok) ||
      _digitWords.containsKey(tok) ||
      _fusedWords.containsKey(tok) ||
      _scaleWords.containsKey(tok) ||
      tok == 'ratus' ||
      tok == 'puluh' ||
      tok == 'belas' ||
      idMsAmountFillerWords.contains(tok);
}

/// Pisahkan singkatan skala yang menempel ke digit, mis. "50rb" -> "50 rb".
String normalizeIdMsNumericGlue(String text) {
  return text.replaceAllMapped(
    RegExp(r'(\d+)(rb|ribu|jt|juta|k)\b'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
}

/// Konversi rangkaian token angka (digit dan/atau kata) menjadi int.
/// Mendukung kelompok ratus/puluh/belas di dalam satu skala, dan skala
/// ribu/juta/miliar yang menjumlah ke total (mis. "dua juta lima ratus
/// ribu" = 2.000.000 + 500.000).
int? parseIdMsAmount(List<String> tokens) {
  final relevant = tokens
      .where((t) => !idMsAmountFillerWords.contains(t))
      .toList();
  if (relevant.isEmpty) return null;

  var total = 0;
  var periodValue = 0;
  var temp = 0;
  var any = false;

  void flushPeriod(int scale) {
    periodValue += temp;
    temp = 0;
    total += (periodValue == 0 ? 1 : periodValue) * scale;
    periodValue = 0;
  }

  for (final tok in relevant) {
    if (RegExp(r'^\d+$').hasMatch(tok)) {
      temp = int.parse(tok);
      any = true;
    } else if (_digitWords.containsKey(tok)) {
      temp = _digitWords[tok]!;
      any = true;
    } else if (_fusedWords.containsKey(tok)) {
      periodValue += _fusedWords[tok]!;
      temp = 0;
      any = true;
    } else if (tok == 'ratus') {
      periodValue += (temp == 0 ? 1 : temp) * 100;
      temp = 0;
      any = true;
    } else if (tok == 'puluh') {
      periodValue += (temp == 0 ? 1 : temp) * 10;
      temp = 0;
      any = true;
    } else if (tok == 'belas') {
      periodValue += 10 + temp;
      temp = 0;
      any = true;
    } else if (_scaleWords.containsKey(tok)) {
      flushPeriod(_scaleWords[tok]!);
      any = true;
    } else {
      return null;
    }
  }

  periodValue += temp;
  total += periodValue;

  return any ? total : null;
}
