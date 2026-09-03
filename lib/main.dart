import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/root_scaffold.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'core/language/language_providers.dart';

// Sengaja tidak ada kerja berat/sinkron di sini sebelum frame pertama
// (NFR PRD §8: buka aplikasi < 2 detik). Database terenkripsi baru dibuka
// belakangan & async, dipicu saat provider pertama kali dibaca (lihat
// `data/providers.dart` -> `databaseProvider`) — bukan di sini.
void main() {
  runApp(const ProviderScope(child: KasBicaraApp()));
}

class KasBicaraApp extends ConsumerWidget {
  const KasBicaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bahasa aktif dari satu sumber kebenaran (konsep "Trilingual KasBicara"
    // §03): pilihan user -> deteksi (mode auto) -> locale perangkat -> id.
    final language = ref.watch(activeLanguageProvider);

    return MaterialApp(
      title: 'KasBicara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      // Peta varian locale perangkat ke tiga bahasa yang didukung: id* -> id,
      // ms* -> ms, selain itu -> en (pengguna di luar regional ID/MY).
      localeResolutionCallback: (locale, supportedLocales) {
        switch (locale?.languageCode) {
          case 'id':
            return const Locale('id');
          case 'ms':
            return const Locale('ms');
          default:
            return const Locale('en');
        }
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootScaffold(),
    );
  }
}
