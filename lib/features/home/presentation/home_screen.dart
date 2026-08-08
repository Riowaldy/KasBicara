import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/voice_parser.dart';
import '../../../data/providers.dart';
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
    final balanceAsync = ref.watch(balanceProvider);
    final voiceState = ref.watch(voiceInputControllerProvider);

    ref.listen(voiceInputControllerProvider, _handleVoiceStateChange);

    return Scaffold(
      appBar: AppBar(title: const Text('KasBicara')),
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
              'Saldo saat ini',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            _MicButton(state: voiceState, onTap: _onMicTap),
            const SizedBox(height: 16),
            SizedBox(height: 48, child: _buildStatusLine(voiceState)),
            TextButton(
              onPressed: () => _openManualForm(context),
              child: const Text('Tambah manual'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(VoiceInputState state) {
    switch (state.status) {
      case VoiceInputStatus.initializing:
        return Text(
          'Menyiapkan mikrofon...',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case VoiceInputStatus.listening:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            state.transcript.isEmpty ? 'Mendengarkan...' : state.transcript,
            key: const Key('voice-transcript'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      case VoiceInputStatus.processing:
        return Text(
          'Memproses...',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case VoiceInputStatus.idle:
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak ada ucapan terdeteksi. Coba lagi atau isi manual.',
            ),
          ),
        );
        return;
      }

      final draft = const VoiceParser().parse(transcript);
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
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.state, required this.onTap});

  final VoiceInputState state;
  final VoidCallback onTap;

  bool get _isListening => state.status == VoiceInputStatus.listening;
  bool get _isBusy =>
      state.status == VoiceInputStatus.initializing ||
      state.status == VoiceInputStatus.processing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
