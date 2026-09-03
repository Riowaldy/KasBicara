import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_language.dart';

/// Kunci penyimpanan pilihan bahasa. Bukan data sensitif, tapi memakai
/// `flutter_secure_storage` agar konsisten dengan mekanisme penyimpanan
/// aplikasi (lihat `app_database.dart`) tanpa menambah dependency baru.
const _preferenceKey = 'kasbicara_language_preference';

final _secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Pilihan bahasa user (persist). Default `auto`; nilai tersimpan dimuat
/// asynchronous setelah frame pertama agar pembukaan aplikasi tetap < 2 detik
/// (NFR PRD §8) — sama seperti alasan `main.dart` menunda kerja berat.
class LanguagePreferenceNotifier extends StateNotifier<LanguagePreference> {
  LanguagePreferenceNotifier(this._storage) : super(LanguagePreference.auto) {
    _load();
  }

  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _preferenceKey);
      if (raw != null) {
        state = LanguagePreference.values.firstWhere(
          (p) => p.name == raw,
          orElse: () => LanguagePreference.auto,
        );
      }
    } catch (_) {
      // Biarkan default `auto` bila secure storage gagal dibaca.
    }
  }

  Future<void> set(LanguagePreference preference) async {
    state = preference;
    try {
      await _storage.write(key: _preferenceKey, value: preference.name);
    } catch (_) {
      // Perubahan tetap berlaku untuk sesi ini walau gagal dipersist.
    }
  }
}

final languagePreferenceProvider =
    StateNotifierProvider<LanguagePreferenceNotifier, LanguagePreference>(
      (ref) => LanguagePreferenceNotifier(ref.watch(_secureStorageProvider)),
    );

/// Bahasa hasil deteksi ucapan terakhir (mode `auto` saja). `null` = belum ada
/// deteksi yang cukup yakin — lihat konsep §04/§05.
final detectedLanguageProvider = StateProvider<AppLanguage?>((ref) => null);

/// Locale perangkat, dibaca sekali. Dipisah jadi provider agar mudah di-override
/// pada test.
final deviceLocaleProvider = Provider<Locale>((ref) {
  return WidgetsBinding.instance.platformDispatcher.locale;
});

/// Bahasa aktif efektif — satu sumber kebenaran yang dibaca lapis UI, STT, dan
/// parser. Implementasi tangga prioritas konsep §03.
final activeLanguageProvider = Provider<AppLanguage>((ref) {
  final preference = ref.watch(languagePreferenceProvider);
  switch (preference) {
    case LanguagePreference.id:
      return AppLanguage.id;
    case LanguagePreference.ms:
      return AppLanguage.ms;
    case LanguagePreference.en:
      return AppLanguage.en;
    case LanguagePreference.auto:
      return ref.watch(detectedLanguageProvider) ??
          appLanguageFromLocale(ref.watch(deviceLocaleProvider));
  }
});
