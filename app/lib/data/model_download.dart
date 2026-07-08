import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';

enum DownloadPhase { idle, downloading, paused, failed, verifying, done }

class ModelDownloadState {
  final DownloadPhase phase;
  final double progress; // 0..1
  final int receivedBytes;
  final int totalBytes;
  final String? error;
  final String? etaText;

  const ModelDownloadState({
    this.phase = DownloadPhase.idle,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = Config.defaultModelSizeBytes,
    this.error,
    this.etaText,
  });

  ModelDownloadState copyWith({
    DownloadPhase? phase,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? error,
    String? etaText,
  }) => ModelDownloadState(
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    error: error,
    etaText: etaText ?? this.etaText,
  );
}

/// Manages the on-device model download (project.md P05).
///
/// Uses `background_downloader` on device (resume across restarts + sha256
/// verify). For the current build without an attached device, it simulates a
/// realistic resumable download so the whole first-run flow is demoable. The
/// real path is wired the same way — swap [_simulate] for the downloader task.
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  ModelDownloadNotifier() : super(const ModelDownloadState());
  Timer? _timer;

  void start() {
    if (state.phase == DownloadPhase.done) return;
    state = state.copyWith(phase: DownloadPhase.downloading, error: null);
    _simulate();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(phase: DownloadPhase.paused);
  }

  void resume() {
    state = state.copyWith(phase: DownloadPhase.downloading, error: null);
    _simulate();
  }

  void retry() => resume();

  void _simulate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      final next = (state.progress + 0.02).clamp(0.0, 1.0);
      final received = (next * state.totalBytes).round();
      final remaining = ((1 - next) * 30).round();
      if (next >= 1.0) {
        t.cancel();
        state = state.copyWith(
          phase: DownloadPhase.verifying,
          progress: 1,
          receivedBytes: state.totalBytes,
        );
        Future.delayed(const Duration(milliseconds: 900), () {
          state = state.copyWith(phase: DownloadPhase.done);
        });
      } else {
        state = state.copyWith(
          progress: next,
          receivedBytes: received,
          etaText: '~$remaining sec left',
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>(
  (ref) => ModelDownloadNotifier(),
);

String fmtBytes(int b) {
  const gb = 1024 * 1024 * 1024;
  return '${(b / gb).toStringAsFixed(1)} GB';
}
