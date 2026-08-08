import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/root_scaffold.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

// Sengaja tidak ada kerja berat/sinkron di sini sebelum frame pertama
// (NFR PRD §8: buka aplikasi < 2 detik). Database terenkripsi baru dibuka
// belakangan & async, dipicu saat provider pertama kali dibaca (lihat
// `data/providers.dart` -> `databaseProvider`) — bukan di sini.
void main() {
  runApp(const ProviderScope(child: KasBicaraApp()));
}

class KasBicaraApp extends StatelessWidget {
  const KasBicaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KasBicara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Bahasa Indonesia sebagai default (PRD §8 NFR Lokalisasi) — juga
      // melokalkan widget bawaan Flutter (mis. showDatePicker) ke id_ID,
      // bukan cuma teks kustom kita sendiri.
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
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
