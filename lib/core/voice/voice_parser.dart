import '../../data/models/transaction_type.dart';

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

/// Kontrak parser ucapan → draft transaksi. Implementasi per bahasa dipilih
/// lewat `voiceParserProvider` berdasarkan `activeLanguageProvider`.
abstract class VoiceParser {
  const VoiceParser();

  VoiceParseResult parse(String rawTranscript);
}

/// Algoritma pola umum FR-2 — `[jenis] [jumlah] (penghubung) [keterangan]` —
/// yang identik untuk ketiga bahasa. Yang berbeda hanya kamus kata kunci dan
/// cara mengurai angka; subclass menyediakannya lewat getter/method abstrak.
///
/// Di luar pola ini parser sengaja mundur (field dibiarkan kosong) alih-alih
/// menebak.
abstract class KeywordVoiceParser extends VoiceParser {
  const KeywordVoiceParser();

  /// Kata kunci penanda transaksi keluar / masuk.
  Set<String> get outKeywords;
  Set<String> get inKeywords;

  /// Kata penghubung sebelum keterangan (mis. `untuk`, `for`) yang dibuang
  /// dari note.
  Set<String> get connectorWords;

  /// Kata pengisi di sekitar angka (mis. `rp`, `sebesar`, `a`) yang dilewati.
  Set<String> get amountFillerWords;

  /// Kata kunci kategori — dicek berurutan, kecocokan pertama menang.
  Map<String, String> get categoryKeywords;

  /// Apakah token termasuk bagian dari rangkaian angka bahasa ini.
  bool isNumberToken(String token);

  /// Konversi rangkaian token angka menjadi int, atau null bila tidak yakin.
  int? parseAmountTokens(List<String> tokens);

  /// Pisahkan singkatan skala yang menempel ke digit sebelum tokenisasi,
  /// mis. `50rb` → `50 rb`, `50k` → `50 k`.
  String normalizeNumericGlue(String text);

  @override
  VoiceParseResult parse(String rawTranscript) {
    final tokens = _tokenize(rawTranscript);

    TransactionType? type;
    var cursor = 0;
    for (var i = 0; i < tokens.length; i++) {
      if (outKeywords.contains(tokens[i])) {
        type = TransactionType.keluar;
        cursor = i + 1;
        break;
      }
      if (inKeywords.contains(tokens[i])) {
        type = TransactionType.masuk;
        cursor = i + 1;
        break;
      }
    }

    while (cursor < tokens.length &&
        amountFillerWords.contains(tokens[cursor])) {
      cursor++;
    }

    final amountStart = cursor;
    while (cursor < tokens.length && isNumberToken(tokens[cursor])) {
      cursor++;
    }
    final amountTokens = tokens.sublist(amountStart, cursor);

    int? amount;
    var amountConfident = false;
    if (amountTokens.isNotEmpty) {
      final parsed = parseAmountTokens(amountTokens);
      if (parsed != null && parsed > 0) {
        amount = parsed;
        amountConfident = true;
      }
    }

    var noteStart = cursor;
    if (noteStart < tokens.length &&
        connectorWords.contains(tokens[noteStart])) {
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

  String? _guessCategory(String text) {
    for (final entry in categoryKeywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  List<String> _tokenize(String input) {
    var text = input.toLowerCase().trim();
    text = stripThousandSeparators(text);
    text = normalizeNumericGlue(text);
    // Buang tanda baca sisanya, rapikan spasi berlebih.
    text = text.replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? const [] : text.split(' ');
  }
}

/// Rapikan angka berformat "50.000" / "2,500,000" jadi digit polos. Menangani
/// pemisah titik (id/ms) maupun koma (en).
String stripThousandSeparators(String text) {
  return text.replaceAllMapped(
    RegExp(r'\d{1,3}(?:[.,]\d{3})+'),
    (m) => m.group(0)!.replaceAll(RegExp(r'[.,]'), ''),
  );
}
