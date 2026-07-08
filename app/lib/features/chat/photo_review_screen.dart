import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P09 — review the captured frame, add a caption, then send it to the model.
class PhotoReviewScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String intent;
  const PhotoReviewScreen({super.key, required this.imagePath, required this.intent});

  @override
  ConsumerState<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends ConsumerState<PhotoReviewScreen> {
  final _caption = TextEditingController();
  int _quarterTurns = 0;
  bool _processing = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  String get _schemaHint {
    switch (widget.intent) {
      case 'somo':
        return 'quiz';
      case 'karani':
        return 'karani';
      case 'expense':
        return 'receipt';
      case 'timetable':
        return 'timetable';
      default:
        return 'karani';
    }
  }

  String get _title {
    switch (widget.intent) {
      case 'somo':
        return 'Notes scan';
      case 'karani':
        return 'Document scan';
      case 'expense':
        return 'Receipt scan';
      case 'timetable':
        return 'Timetable scan';
      default:
        return 'Scan';
    }
  }

  Future<void> _submit() async {
    if (_processing) return;
    setState(() => _processing = true);

    final gemma = ref.read(gemmaProvider);
    final db = ref.read(dbProvider);
    try {
      final result = await gemma.structured(
        _caption.text.trim().isEmpty ? 'Read this image' : _caption.text.trim(),
        imagePath: widget.imagePath,
        schemaHint: _schemaHint,
      );

      final confidence = (result['confidence'] as num?)?.toDouble() ?? 1.0;
      final sensitive = result['topicSensitive'] == true;

      final scanId = await db.into(db.scans).insert(
            ScansCompanion.insert(
              type: widget.intent == 'expense' ? 'receipt' : widget.intent,
              title: _caption.text.trim().isEmpty ? _title : _caption.text.trim(),
              resultJson: jsonEncode(result),
              photoPath: Value(widget.imagePath),
              confidence: Value(confidence),
              topicSensitive: Value(sensitive),
            ),
          );

      if (!mounted) return;
      switch (widget.intent) {
        case 'somo':
          context.go('/somo/result?id=$scanId');
          break;
        case 'karani':
          context.go('/karani/doc?id=$scanId');
          break;
        case 'expense':
          context.go('/hustle/transactions/edit?scanId=$scanId');
          break;
        case 'timetable':
          context.go('/ratiba/timetable?scanId=$scanId');
          break;
        default:
          context.go('/karani/doc?id=$scanId');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _processing = false);
        poa(context, ref.l10n.scanFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.l10n;
    final hasImage = widget.imagePath.isNotEmpty && File(widget.imagePath).existsSync();
    return Stack(
      children: [
        TccScaffold(
          title: t.reviewPhoto,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image preview.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(TCC.radius),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 200, maxHeight: 420),
                          color: TCC.surface,
                          alignment: Alignment.center,
                          child: hasImage
                              ? RotatedBox(
                                  quarterTurns: _quarterTurns,
                                  child: Image.file(File(widget.imagePath),
                                      fit: BoxFit.contain),
                                )
                              : const Padding(
                                  padding: EdgeInsets.all(48),
                                  child: Icon(Icons.broken_image_rounded,
                                      color: TCC.textMuted, size: 48),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Toolbar.
                      Row(
                        children: [
                          _ToolBtn(
                            icon: Icons.rotate_right_rounded,
                            label: t.rotate,
                            onTap: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
                          ),
                          const SizedBox(width: 12),
                          _ToolBtn(
                            icon: Icons.replay_rounded,
                            label: t.retake,
                            onTap: () => context.pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t.captionOptional,
                        style: const TextStyle(color: TCC.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _caption,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: t.captionHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Send bar.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: TCC.bg,
                  border: Border(top: BorderSide(color: TCC.border)),
                ),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _processing ? null : _submit,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text(t.send),
                    style: FilledButton.styleFrom(
                      backgroundColor: TCC.accent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_processing) _LoadingOverlay(title: t.readingImage, subtitle: t.oneMoment),
      ],
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TCC.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: TCC.surface2,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: TCC.text),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: TCC.text, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  const _LoadingOverlay({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3, color: TCC.accent),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(color: TCC.text, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
