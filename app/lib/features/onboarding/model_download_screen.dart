import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../core/config.dart';
import '../../data/model_download.dart';
import '../../theme/tokens.dart';

/// P04–P05 — "Get your AI ready" model download, all states.
class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});
  @override
  ConsumerState<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  bool _whyExpanded = false;

  @override
  void initState() {
    super.initState();
    ref.read(appFlagsProvider.notifier).setOnboarded(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(modelDownloadProvider);
    final n = ref.read(modelDownloadProvider.notifier);

    ref.listen(modelDownloadProvider, (prev, next) {
      if (next.phase == DownloadPhase.done) {
        ref.read(appFlagsProvider.notifier).setModelReady(true);
      }
    });

    return Scaffold(
      backgroundColor: TCC.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: TCC.textMuted),
                        onPressed: () => context.go('/onboarding/2'),
                      ),
                      SvgPicture.asset(
                        'assets/brand/logo_icon.svg',
                        width: 28,
                        height: 28,
                      ),
                    ],
                  ),
                  const SizedBox(),
                ],
              ),
              const Spacer(),
              Text('Get your AI ready.', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'TCC runs fully on your phone. We need to download its model once '
                '— about ${fmtBytes(Config.defaultModelSizeBytes)}.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TCC.textMuted),
              ),
              const SizedBox(height: 24),
              _StorageLine(),
              const SizedBox(height: 16),
              if (s.phase == DownloadPhase.idle || s.phase == DownloadPhase.failed)
                _wifiBanner(),
              const SizedBox(height: 28),
              Center(child: _progress(s)),
              const Spacer(),
              _cta(context, s, n),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _whyExpanded = !_whyExpanded),
                  child: Text(_whyExpanded ? 'Hide' : 'Why?',
                      style: const TextStyle(color: TCC.textMuted)),
                ),
              ),
              if (_whyExpanded)
                Text(
                  'Running the model on your device means no internet is needed after '
                  'this, your data never leaves the phone, and it works even with no '
                  'bundles. Download once, use offline forever.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wifiBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TCC.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TCC.radiusSm),
          border: Border.all(color: TCC.warning.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.wifi_rounded, color: TCC.warning, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text('Use Wi-Fi — this is a big download.',
                  style: TextStyle(color: TCC.text, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _progress(ModelDownloadState s) {
    final pct = (s.progress * 100).round();
    if (s.phase == DownloadPhase.done) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TCC.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: TCC.accent, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Success! Your AI is ready.',
              style: TextStyle(color: TCC.text, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      );
    }
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: s.phase == DownloadPhase.verifying ? null : s.progress,
              strokeWidth: 8,
              backgroundColor: TCC.surface2,
              valueColor: const AlwaysStoppedAnimation(TCC.accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.phase == DownloadPhase.verifying ? '...' : '$pct%',
                style: const TextStyle(color: TCC.text, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              if (s.phase == DownloadPhase.downloading)
                Text('${fmtBytes(s.receivedBytes)} / ${fmtBytes(s.totalBytes)}',
                    style: const TextStyle(color: TCC.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cta(BuildContext context, ModelDownloadState s, ModelDownloadNotifier n) {
    switch (s.phase) {
      case DownloadPhase.idle:
        return FilledButton(
            onPressed: n.start,
            child: Text('Download now (${fmtBytes(Config.defaultModelSizeBytes)})'));
      case DownloadPhase.downloading:
        return Column(
          children: [
            if (s.etaText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${s.etaText} · Do not close the app',
                    style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
              ),
            OutlinedButton(onPressed: n.pause, child: const Text('Pause')),
          ],
        );
      case DownloadPhase.paused:
        return FilledButton(onPressed: n.resume, child: const Text('Resume download'));
      case DownloadPhase.failed:
        return Column(
          children: [
            const Text('Download failed. Check your connection.',
                style: TextStyle(color: TCC.danger, fontSize: 13)),
            const SizedBox(height: 12),
            FilledButton(onPressed: n.retry, child: const Text('Retry')),
          ],
        );
      case DownloadPhase.verifying:
        return const Center(
          child: Text('Verifying... almost there.',
              style: TextStyle(color: TCC.textMuted)),
        );
      case DownloadPhase.done:
        return FilledButton(
          onPressed: () => context.go('/chat'),
          child: const Text('Get Started'),
        );
    }
  }
}

class _StorageLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sd_storage_outlined, size: 18, color: TCC.textMuted),
        const SizedBox(width: 8),
        Text('Space needed: ${fmtBytes(Config.defaultModelSizeBytes)}',
            style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
        const SizedBox(width: 8),
        const Icon(Icons.check_circle, size: 16, color: TCC.accent),
      ],
    );
  }
}
