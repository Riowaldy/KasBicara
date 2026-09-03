import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../language/app_language.dart';
import '../language/language_providers.dart';
import 'en_voice_parser.dart';
import 'id_voice_parser.dart';
import 'ms_voice_parser.dart';
import 'voice_parser.dart';

/// Parser ucapan yang sesuai dengan bahasa aktif (konsep §06).
final voiceParserProvider = Provider<VoiceParser>((ref) {
  switch (ref.watch(activeLanguageProvider)) {
    case AppLanguage.id:
      return const IdVoiceParser();
    case AppLanguage.ms:
      return const MsVoiceParser();
    case AppLanguage.en:
      return const EnVoiceParser();
  }
});
