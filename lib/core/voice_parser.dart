import '../data/models/transaction_type.dart';

/// Hasil parsing satu transkrip ucapan menjadi draft transaksi.
///
/// `amount` HANYA diisi jika [amountConfident] true — sesuai mitigasi
/// risiko PRD §13: jumlah tidak boleh ditebak. Jika parser tidak yakin,
/// field jumlah dibiarkan kosong agar pengguna melengkapi manual.
class VoiceParseResult {
  const VoiceParseResult({
    required this.rawTranscript,
    this.type,
    this.amount,
    this.amountConfident = false,
    this.category,
    this.note,
  });

  final String rawTranscript;
  final TransactionType? type;
  final int? amount;
  final bool amountConfident;

  /// ID kategori tebakan (lihat `default_categories.dart`), boleh null.
  final String? category;
  final String? note;
}

/// Parser ucapan Bahasa Indonesia → draft transaksi (PRD §6.1, §10).
///
/// Mendukung pola umum FR-2: `[jenis] [jumlah] (untuk|buat) [keterangan]`,
/// termasuk jumlah dalam bentuk digit maupun kata ("lima puluh ribu", "dua
/// juta lima ratus ribu"). Di luar pola ini, parser sengaja mundur (field
/// dibiarkan kosong) alih-alih menebak — lihat komentar di [parse].
class VoiceParser {
  const VoiceParser();

  static const _keluarKeywords = {
    'keluar',
    'bayar',
    'membayar',
    'beli',
    'membeli',
    'belanja',
    'habis',
    'pengeluaran',
    'keluarkan',
  };

  static const _masukKeywords = {
    'masuk',
    'terima',
    'menerima',
    'nerima',
    'dapat',
    'dapet',
    'pemasukan',
  };

  static const _connectorWords = {'untuk', 'buat', 'buad', 'buwat'};

  static const _amountFillerWords = {
    'rp',
    'rupiah',
    'uang',
    'sebesar',
    'sejumlah',
    'senilai',
    'sekitar',
  };

  static const _digitWords = {
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

  static const _fusedWords = {
    'sepuluh': 10,
    'sebelas': 11,
    'seratus': 100,
    'seribu': 1000,
    'sejuta': 1000000,
    'semiliar': 1000000000,
  };

  static const _scaleWords = {
    'ribu': 1000,
    'rb': 1000,
    'k': 1000,
    'juta': 1000000,
    'jt': 1000000,
    'miliar': 1000000000,
    'milyar': 1000000000,
  };

  /// Kata kunci kategori — dicek berurutan, kecocokan pertama menang.
  /// Best-effort saja: berbeda dari `amount`, salah tebak kategori risikonya
  /// rendah (mudah dikoreksi lewat dropdown) sehingga tetap boleh diisi.
  static const _categoryKeywords = <String, String>{
    'makan': 'expense-makanan-minuman',
    'minum': 'expense-makanan-minuman',
    'sarapan': 'expense-makanan-minuman',
    'jajan': 'expense-makanan-minuman',
    'kopi': 'expense-makanan-minuman',
    'restoran': 'expense-makanan-minuman',
    'bensin': 'expense-transportasi',
    'ojek': 'expense-transportasi',
    'gojek': 'expense-transportasi',
    'grab': 'expense-transportasi',
    'angkot': 'expense-transportasi',
    'parkir': 'expense-transportasi',
    'busway': 'expense-transportasi',
    'kereta': 'expense-transportasi',
    'taksi': 'expense-transportasi',
    'belanja': 'expense-belanja',
    'baju': 'expense-belanja',
    'sepatu': 'expense-belanja',
    'listrik': 'expense-tagihan-utilitas',
    'pulsa': 'expense-tagihan-utilitas',
    'internet': 'expense-tagihan-utilitas',
    'wifi': 'expense-tagihan-utilitas',
    'obat': 'expense-kesehatan',
    'dokter': 'expense-kesehatan',
    'rumahsakit': 'expense-kesehatan',
    'nonton': 'expense-hiburan',
    'bioskop': 'expense-hiburan',
    'game': 'expense-hiburan',
    'buku': 'expense-pendidikan',
    'kuliah': 'expense-pendidikan',
    'sekolah': 'expense-pendidikan',
    'gaji': 'income-gaji',
    'bonus': 'income-bonus',
    'investasi': 'income-investasi',
    'saham': 'income-investasi',
    'transfer': 'income-transfer-masuk',
  };

  VoiceParseResult parse(String rawTranscript) {
    final tokens = _tokenize(rawTranscript);

    TransactionType? type;
    var cursor = 0;
    for (var i = 0; i < tokens.length; i++) {
      if (_keluarKeywords.contains(tokens[i])) {
        type = TransactionType.keluar;
        cursor = i + 1;
        break;
      }
      if (_masukKeywords.contains(tokens[i])) {
        type = TransactionType.masuk;
        cursor = i + 1;
        break;
      }
    }

    while (cursor < tokens.length &&
        _amountFillerWords.contains(tokens[cursor])) {
      cursor++;
    }

    final amountStart = cursor;
    while (cursor < tokens.length && _isNumberToken(tokens[cursor])) {
      cursor++;
    }
    final amountTokens = tokens.sublist(amountStart, cursor);

    int? amount;
    var amountConfident = false;
    if (amountTokens.isNotEmpty) {
      final parsed = _parseAmountTokens(amountTokens);
      if (parsed != null && parsed > 0) {
        amount = parsed;
        amountConfident = true;
      }
    }

    var noteStart = cursor;
    if (noteStart < tokens.length &&
        _connectorWords.contains(tokens[noteStart])) {
      noteStart++;
    }
    final noteTokens = tokens.sublist(noteStart);
    final note = noteTokens.isEmpty ? null : noteTokens.join(' ');

    return VoiceParseResult(
      rawTranscript: rawTranscript,
      type: type,
      amount: amount,
      amountConfident: amountConfident,
      category: _guessCategory(note ?? tokens.join(' ')),
      note: note,
    );
  }

  bool _isNumberToken(String tok) {
    return RegExp(r'^\d+$').hasMatch(tok) ||
        _digitWords.containsKey(tok) ||
        _fusedWords.containsKey(tok) ||
        _scaleWords.containsKey(tok) ||
        tok == 'ratus' ||
        tok == 'puluh' ||
        tok == 'belas' ||
        _amountFillerWords.contains(tok);
  }

  /// Konversi rangkaian token angka (digit dan/atau kata) menjadi int.
  /// Mendukung kelompok ratus/puluh/belas di dalam satu skala, dan skala
  /// ribu/juta/miliar yang menjumlah ke total (mis. "dua juta lima ratus
  /// ribu" = 2.000.000 + 500.000).
  int? _parseAmountTokens(List<String> tokens) {
    final relevant = tokens
        .where((t) => !_amountFillerWords.contains(t))
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

  String? _guessCategory(String text) {
    for (final entry in _categoryKeywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  List<String> _tokenize(String input) {
    var text = input.toLowerCase().trim();

    // Rapikan angka berformat "50.000" / "2.500.000" jadi digit polos.
    text = text.replaceAllMapped(
      RegExp(r'\d{1,3}(?:[.,]\d{3})+'),
      (m) => m.group(0)!.replaceAll(RegExp(r'[.,]'), ''),
    );

    // Pisahkan singkatan skala yang menempel ke digit, mis. "50rb" -> "50 rb".
    text = text.replaceAllMapped(
      RegExp(r'(\d+)(rb|ribu|jt|juta|k)\b'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    // Buang tanda baca sisanya, rapikan spasi berlebih.
    text = text.replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text.isEmpty ? const [] : text.split(' ');
  }
}
