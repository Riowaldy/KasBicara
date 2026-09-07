import 'package:flutter/widgets.dart' show Locale;

/// Bahasa aktual yang sedang dipakai aplikasi (bukan pilihan mentah user).
///
/// Setiap nilai membawa [locale] untuk lapis UI/ARB dan [sttLocaleId] untuk
/// `speech_to_text` (lihat konsep "Trilingual KasBicara" §02 & §05).
enum AppLanguage {
  id(Locale('id'), 'id_ID'),
  ms(Locale('ms'), 'ms_MY'),
  en(Locale('en'), 'en_US');

  const AppLanguage(this.locale, this.sttLocaleId);

  final Locale locale;
  final String sttLocaleId;
}

/// Pilihan bahasa di layar Setelan. `auto` = ikuti detektor + locale perangkat.
enum LanguagePreference { auto, id, ms, en }

/// Petakan locale perangkat ke [AppLanguage] mengikuti lokasi/regional user —
/// konsep §03 tangga langkah 3:
///
/// 1. Negara perangkat: `ID` -> id, `MY` -> ms (menang lebih dulu agar user di
///    Indonesia/Malaysia tetap dapat bahasa lokal walau bahasa ponselnya lain).
/// 2. Bahasa perangkat: `id*` -> id, `ms*` -> ms.
/// 3. Di luar keduanya -> en.
AppLanguage appLanguageFromLocale(Locale locale) {
  switch (locale.countryCode) {
    case 'ID':
      return AppLanguage.id;
    case 'MY':
      return AppLanguage.ms;
  }
  switch (locale.languageCode) {
    case 'id':
      return AppLanguage.id;
    case 'ms':
      return AppLanguage.ms;
    default:
      return AppLanguage.en;
  }
}
