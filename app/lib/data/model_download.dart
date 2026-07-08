import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../llm/flutter_gemma_service.dart';

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

/// Manages the real on-device model download (project.md P05) through
/// flutter_gemma's ModelFileManager, which uses `background_downloader`
/// underneath: resumable across interruptions and app restarts. The spec is
/// shared with [FlutterGemmaService] so download and inference always agree
/// on the model.
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  ModelDownloadNotifier() : super(const ModelDownloadState());

  final _mgr = FlutterGemmaPlugin.instance.modelManager;
  StreamSubscription<DownloadProgress>? _sub;
  DateTime? _startedAt;

  Future<void> start() async {
    if (state.phase == DownloadPhase.done ||
        state.phase == DownloadPhase.downloading) {
      return;
    }
    state = state.copyWith(phase: DownloadPhase.downloading, error: null);
    try {
      if (await _mgr.isModelInstalled(FlutterGemmaService.modelSpec)) {
        state = state.copyWith(
          phase: DownloadPhase.done,
          progress: 1,
          receivedBytes: state.totalBytes,
        );
        return;
      }
      _startedAt = DateTime.now();
      _sub = _mgr
          .downloadModelWithProgress(FlutterGemmaService.modelSpec)
          .listen(_onProgress, onError: _onError, onDone: _onDone);
    } catch (e) {
      _onError(e);
    }
  }

  void _onProgress(DownloadProgress p) {
    final frac = (p.overallProgress / 100).clamp(0.0, 1.0);
    state = state.copyWith(
      phase: DownloadPhase.downloading,
      progress: frac,
      receivedBytes: (frac * state.totalBytes).round(),
      etaText: _eta(frac),
    );
  }

  Future<void> _onDone() async {
    state = state.copyWith(phase: DownloadPhase.verifying, progress: 1);
    try {
      final ok = await _mgr.validateModel(FlutterGemmaService.modelSpec);
      if (!ok) {
        state = state.copyWith(
          phase: DownloadPhase.failed,
          error: 'Model file failed verification — jaribu tena.',
        );
        return;
      }
      _mgr.setActiveModel(FlutterGemmaService.modelSpec);
      state = state.copyWith(
        phase: DownloadPhase.done,
        receivedBytes: state.totalBytes,
      );
    } catch (e) {
      _onError(e);
    }
  }

  void _onError(Object e) {
    _sub?.cancel();
    _sub = null;
    if (!mounted) return;
    state = state.copyWith(phase: DownloadPhase.failed, error: e.toString());
  }

  /// Pausing cancels the stream; `background_downloader` keeps the partial
  /// file, so the next [resume] continues from the last byte.
  void pause() {
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(phase: DownloadPhase.paused);
  }

  void resume() => start();

  void retry() {
    state = state.copyWith(phase: DownloadPhase.idle, error: null);
    start();
  }

  String? _eta(double frac) {
    final started = _startedAt;
    if (started == null || frac <= 0.01) return null;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final remaining = (elapsed / frac * (1 - frac)).round();
    if (remaining > 5400) return null; // beyond an ETA anyone believes
    if (remaining >= 60) return '~${(remaining / 60).round()} min left';
    return '~$remaining sec left';
  }

  @override
  void dispose() {
    _sub?.cancel();
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
