import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/language/app_language.dart';
import '../../../core/language/language_providers.dart';
import '../../../core/voice/language_detector.dart';

/// Status sesi pengenalan suara (PRD §6.1, §11 Flow A).
enum VoiceInputStatus {
  idle,
  initializing,
  listening,
  processing,
  done,

  /// Mic/izin tidak tersedia — UI harus mengarahkan ke input manual
  /// (mitigasi risiko PRD §13, fallback selalu tersedia).
  unavailable,
  error,
}

class VoiceInputState {
  const VoiceInputState({
    this.status = VoiceInputStatus.idle,
    this.transcript = '',
    this.errorMessage,
    this.detectedLanguage,
  });

  final VoiceInputStatus status;
  final String transcript;
  final String? errorMessage;

  /// Diisi hanya bila deteksi mengganti bahasa aktif pada sesi ini (mode
  /// `auto`) — dipakai UI untuk memberi tahu pengguna. Konsep §05 langkah 4.
  final AppLanguage? detectedLanguage;

  VoiceInputState copyWith({
    VoiceInputStatus? status,
    String? transcript,
    Object? errorMessage = _sentinel,
    Object? detectedLanguage = _sentinel,
  }) {
    return VoiceInputState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      detectedLanguage: identical(detectedLanguage, _sentinel)
          ? this.detectedLanguage
          : detectedLanguage as AppLanguage?,
    );
  }
}

const _sentinel = Object();

/// Mengelola satu sesi `speech_to_text`: mulai/berhenti mendengarkan,
/// transkrip live, dan status untuk indikator visual (FR-1). Bahasa STT
/// mengikuti `activeLanguageProvider`; setelah transkrip final, transkrip
/// dijalankan lewat [LanguageDetector] untuk kemungkinan berpindah bahasa
/// pada mode `auto` (konsep "Trilingual KasBicara" §05).
class VoiceInputController extends StateNotifier<VoiceInputState> {
  VoiceInputController(this._ref) : super(const VoiceInputState());

  final Ref _ref;
  final stt.SpeechToText _speech = stt.SpeechToText();
  static const _detector = LanguageDetector();

  Future<void> startListening() async {
    state = const VoiceInputState(status: VoiceInputStatus.initializing);

    bool available;
    try {
      available = await _speech.initialize(
        onError: (error) {
          state = state.copyWith(
            status: VoiceInputStatus.error,
            errorMessage: error.errorMsg,
          );
        },
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') &&
              state.status == VoiceInputStatus.listening) {
            state = state.copyWith(status: VoiceInputStatus.done);
          }
        },
      );
    } catch (_) {
      available = false;
    }

    if (!available) {
      state = state.copyWith(
        status: VoiceInputStatus.unavailable,
        errorMessage:
            'Mikrofon tidak tersedia atau izin ditolak. Gunakan input manual.',
      );
      return;
    }

    state = state.copyWith(status: VoiceInputStatus.listening, transcript: '');
    await _speech.listen(
      onResult: _onResult,
      listenOptions: stt.SpeechListenOptions(
        localeId: _ref.read(activeLanguageProvider).sttLocaleId,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    state = state.copyWith(transcript: result.recognizedWords);
    if (result.finalResult) {
      _runDetection(result.recognizedWords);
      state = state.copyWith(status: VoiceInputStatus.done);
    }
  }

  /// Jalankan detektor bahasa pada transkrip final. Hanya berpengaruh saat
  /// pilihan user `auto`, deteksi cukup yakin, dan berbeda dari bahasa aktif.
  void _runDetection(String transcript) {
    if (_ref.read(languagePreferenceProvider) != LanguagePreference.auto) {
      return;
    }
    final guess = _detector.detect(transcript);
    if (guess.ambiguous || guess.confidence < 0.6) return;

    final current = _ref.read(activeLanguageProvider);
    if (guess.language == current) return;

    _ref.read(detectedLanguageProvider.notifier).state = guess.language;
    state = state.copyWith(detectedLanguage: guess.language);
  }

  Future<void> stopListening() async {
    if (state.status != VoiceInputStatus.listening) return;
    state = state.copyWith(status: VoiceInputStatus.processing);
    await _speech.stop();
  }

  /// Kembalikan ke idle — dipanggil setelah draft ditindaklanjuti (disimpan
  /// atau dibatalkan) agar mic siap dipakai lagi.
  void reset() {
    state = const VoiceInputState();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}

final voiceInputControllerProvider =
    StateNotifierProvider<VoiceInputController, VoiceInputState>(
      (ref) => VoiceInputController(ref),
    );
