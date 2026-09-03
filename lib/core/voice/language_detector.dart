import '../language/app_language.dart';
import 'language_markers.dart';

/// Hasil deteksi bahasa satu transkrip.
///
/// [ambiguous] true berarti bukti terlalu tipis — pemanggil TIDAK boleh
/// mengganti bahasa otomatis, pakai bahasa sesi berjalan (konsep §04/§05).
class LanguageGuess {
  const LanguageGuess(
    this.language,
    this.confidence, {
    required this.ambiguous,
  });

  final AppLanguage language;

  /// 0..1.
  final double confidence;
  final bool ambiguous;
}

/// Detektor bahasa dua tahap (konsep "Trilingual KasBicara" §04):
/// 1. Gerbang Inggris — mudah, kosakata & kata fungsi berbeda tajam.
/// 2. Skor leksikal berbobot Indonesia vs Melayu — dua bahasa yang mirip,
///    jadi berani menyatakan `ambiguous` saat buktinya tipis.
class LanguageDetector {
  const LanguageDetector();

  /// Ambang skor gerbang Inggris.
  static const kEnGate = 4;

  /// Pembagi normalisasi confidence tahap 2.
  static const kIdMsK = 4;

  /// Ambang di bawah mana selisih id/ms dianggap ambigu.
  static const kIdMsThreshold = 2;

  LanguageGuess detect(String transcript) {
    final tokens = _tokenize(transcript);
    if (tokens.isEmpty) {
      return const LanguageGuess(AppLanguage.id, 0, ambiguous: true);
    }

    // --- Tahap 1: gerbang Inggris ---
    var enScore = 0;
    for (final tok in tokens) {
      if (enVerbMarkers.contains(tok)) {
        enScore += 3;
      } else if (enFunctionMarkers.contains(tok)) {
        enScore += 2;
      }
    }
    if (enScore >= kEnGate) {
      return LanguageGuess(
        AppLanguage.en,
        (enScore / 6).clamp(0.0, 1.0),
        ambiguous: false,
      );
    }

    // --- Tahap 2: Indonesia vs Melayu ---
    // delta > 0 -> condong Melayu; delta < 0 -> condong Indonesia.
    var delta = 0;
    for (final tok in tokens) {
      delta += _weight(tok, isMalay: true) - _weight(tok, isMalay: false);
    }

    final language = delta > 0 ? AppLanguage.ms : AppLanguage.id;
    final confidence = (delta.abs() / kIdMsK).clamp(0.0, 1.0);
    final ambiguous = delta.abs() < kIdMsThreshold;

    return LanguageGuess(language, confidence, ambiguous: ambiguous);
  }

  int _weight(String tok, {required bool isMalay}) {
    if (isMalay) {
      if (msCurrencyMarkers.contains(tok)) return 3;
      if (msLexicalMarkers.contains(tok)) return 2;
      if (msFunctionMarkers.contains(tok)) return 1;
      return 0;
    }
    if (idCurrencyMarkers.contains(tok)) return 3;
    if (idLexicalMarkers.contains(tok)) return 2;
    if (idFunctionMarkers.contains(tok)) return 1;
    return 0;
  }

  List<String> _tokenize(String input) {
    final text = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? const [] : text.split(' ');
  }
}
