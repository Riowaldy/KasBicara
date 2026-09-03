import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/app_language.dart';
import '../../../core/language/language_providers.dart';
import '../../../l10n/app_localizations.dart';

/// Pemilih bahasa (konsep "Trilingual KasBicara" §08): Otomatis / Indonesia /
/// Melayu / English. Memilih bahasa spesifik mengunci ketiga lapis dan
/// mematikan detektor.
Future<void> showLanguageDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<void>(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(languagePreferenceProvider);

          void select(LanguagePreference? preference) {
            if (preference == null) return;
            ref.read(languagePreferenceProvider.notifier).set(preference);
            // Bersihkan hasil deteksi lama agar pilihan baru langsung berlaku.
            ref.read(detectedLanguageProvider.notifier).state = null;
            Navigator.of(context).pop();
          }

          return SimpleDialog(
            title: Text(l10n.settingsLanguage),
            children: [
              RadioGroup<LanguagePreference>(
                groupValue: current,
                onChanged: select,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<LanguagePreference>(
                      value: LanguagePreference.auto,
                      title: Text(l10n.settingsLanguageAuto),
                    ),
                    RadioListTile<LanguagePreference>(
                      value: LanguagePreference.id,
                      title: Text(l10n.languageNameId),
                    ),
                    RadioListTile<LanguagePreference>(
                      value: LanguagePreference.ms,
                      title: Text(l10n.languageNameMs),
                    ),
                    RadioListTile<LanguagePreference>(
                      value: LanguagePreference.en,
                      title: Text(l10n.languageNameEn),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
