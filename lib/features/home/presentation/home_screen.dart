import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/voice/voice_parser_provider.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/language_dialog.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/voice_input_controller.dart';

/// Layar Beranda — Flow A (PRD §11): tekan mic, bicara, tinjau draft di
/// kartu konfirmasi. Input manual (Fase 2) tetap tersedia sebagai pelengkap
/// & fallback bila suara tidak tersedia (PRD §13).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(balanceProvider);
    final voiceState = ref.watch(voiceInputControllerProvider);

    ref.listen(voiceInputControllerProvider, _handleVoiceStateChange);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KasBicara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: l10n.settingsLanguageTooltip,
            onPressed: () => showLanguageDialog(context, ref),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            balanceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Gagal memuat saldo: $e'),
              data: (balance) => Text(
                formatRupiah(balance),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeBalanceLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            _MicButton(state: voiceState, onTap: _onMicTap),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: _buildStatusLine(voiceState, l10n),
            ),
            TextButton(
              onPressed: () => _openManualForm(context),
              child: Text(l10n.homeAddManual),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(VoiceInputState state, AppLocalizations l10n) {
    switch (state.status) {
      case VoiceInputStatus.initializing:
        return Text(
          l10n.homePreparingMic,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case VoiceInputStatus.listening:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            state.transcript.isEmpty ? l10n.homeListening : state.transcript,
            key: const Key('voice-transcript'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      case VoiceInputStatus.processing:
        return Text(
          l10n.homeProcessing,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case VoiceInputStatus.idle:
        // Contoh ucapan agar pengguna tidak bingung mau bilang apa — hilang
        // begitu mic mulai mendengarkan (transcript live mengambil alih).
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.homeVoiceExampleTitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeVoiceExampleExpense,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
              Text(
                l10n.homeVoiceExampleIncome,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      case VoiceInputStatus.done:
      case VoiceInputStatus.unavailable:
      case VoiceInputStatus.error:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onMicTap() async {
    final controller = ref.read(voiceInputControllerProvider.notifier);
    final status = ref.read(voiceInputControllerProvider).status;

    if (status == VoiceInputStatus.listening) {
      await controller.stopListening();
    } else if (status == VoiceInputStatus.idle ||
        status == VoiceInputStatus.done ||
        status == VoiceInputStatus.unavailable ||
        status == VoiceInputStatus.error) {
      await controller.startListening();
    }
  }

  void _handleVoiceStateChange(
    VoiceInputState? previous,
    VoiceInputState next,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (next.status == VoiceInputStatus.unavailable ||
        next.status == VoiceInputStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.errorMessage ?? 'Terjadi kesalahan pada pengenalan suara.',
          ),
        ),
      );
      return;
    }

    if (next.status == VoiceInputStatus.done) {
      final transcript = next.transcript.trim();
      final controller = ref.read(voiceInputControllerProvider.notifier);

      if (transcript.isEmpty) {
        controller.reset();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.homeNoSpeechDetected)));
        return;
      }

      // Deteksi (mode auto) mungkin sudah mengganti bahasa aktif — beri tahu
      // pengguna sebelum draft dibuka (konsep §05 langkah 4).
      final detected = next.detectedLanguage;
      if (detected != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageDetectedSnack(_languageName(detected, l10n)),
            ),
          ),
        );
      }

      final draft = ref.read(voiceParserProvider).parse(transcript);
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => TransactionFormScreen(voiceDraft: draft),
            ),
          )
          .then((_) => controller.reset());
    }
  }

  Future<void> _openManualForm(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TransactionFormScreen()));
  }

  String _languageName(AppLanguage language, AppLocalizations l10n) {
    switch (language) {
      case AppLanguage.id:
        return l10n.languageNameId;
      case AppLanguage.ms:
        return l10n.languageNameMs;
      case AppLanguage.en:
        return l10n.languageNameEn;
    }
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.state, required this.onTap});

  final VoiceInputState state;
  final VoidCallback onTap;

  bool get _isListening => state.status == VoiceInputStatus.listening;
  bool get _isBusy =>
      state.status == VoiceInputStatus.initializing ||
      state.status == VoiceInputStatus.processing;

  String _semanticLabel(AppLocalizations l10n) {
    if (_isBusy) return l10n.micBusyLabel;
    if (_isListening) return l10n.micListeningLabel;
    return l10n.micIdleLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      enabled: !_isBusy,
      label: _semanticLabel(l10n),
      child: GestureDetector(
        key: const Key('mic-button'),
        onTap: _isBusy ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _isListening ? AppColors.expense : AppColors.gold,
            shape: BoxShape.circle,
            boxShadow: _isListening
                ? [
                    BoxShadow(
                      color: AppColors.expense.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: _isBusy
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(
                    color: AppColors.inkBackground,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic,
                  size: 40,
                  color: AppColors.inkBackground,
                ),
        ),
      ),
    );
  }
}
