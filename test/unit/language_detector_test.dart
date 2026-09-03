import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/language/app_language.dart';
import 'package:kasbicara/core/voice/language_detector.dart';

void main() {
  const detector = LanguageDetector();

  group('Tahap 1 — gerbang Inggris', () {
    test('kata kerja + kata fungsi Inggris -> en, tidak ambigu', () {
      final g = detector.detect('paid two hundred thousand for electricity');
      expect(g.language, AppLanguage.en);
      expect(g.ambiguous, isFalse);
      expect(g.confidence, greaterThanOrEqualTo(0.6));
    });

    test('"spent ... on ..." -> en', () {
      final g = detector.detect('spent fifty thousand on lunch');
      expect(g.language, AppLanguage.en);
      expect(g.ambiguous, isFalse);
    });
  });

  group('Tahap 2 — Indonesia vs Melayu', () {
    test('penanda mata uang + kosakata Melayu -> ms', () {
      final g = detector.detect('beli minyak kereta empat puluh ringgit');
      expect(g.language, AppLanguage.ms);
      expect(g.ambiguous, isFalse);
      expect(g.confidence, 1.0);
    });

    test('kosakata Indonesia -> id', () {
      final g = detector.detect('keluar lima puluh ribu buat bensin');
      expect(g.language, AppLanguage.id);
      expect(g.ambiguous, isFalse);
    });

    test('tanpa penanda khas -> ambigu (tidak menebak)', () {
      final g = detector.detect('masuk gaji dua juta');
      expect(g.ambiguous, isTrue);
    });

    test('transkrip kosong -> ambigu', () {
      final g = detector.detect('');
      expect(g.ambiguous, isTrue);
    });
  });

  group('Campur kode', () {
    test('bingkai Inggris menang walau ada kata Indonesia', () {
      final g = detector.detect('spent fifty ribu buat lunch');
      expect(g.language, AppLanguage.en);
    });
  });
}
