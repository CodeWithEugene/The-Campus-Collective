import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../theme/tokens.dart';

/// P08 — full-screen capture surface. A real camera preview needs the `camera`
/// plugin + device hardware which may be unavailable on E2B, so we drive capture
/// through image_picker (camera OR gallery) behind a premium framing overlay.
class CameraScreen extends ConsumerStatefulWidget {
  final String intent;
  const CameraScreen({super.key, required this.intent});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  String _hint(LangPref lang) {
    final english = <String, String>{
      'karani': 'Fit the fee statement in frame',
      'somo': 'Fit your notes inside the box',
      'expense': 'Snap your receipt',
      'timetable': 'Photograph your timetable',
    };
    final swahili = <String, String>{
      'karani': 'Weka stakabadhi ndani ya fremu',
      'somo': 'Weka notes ndani ya mstari',
      'expense': 'Piga picha risiti yako',
      'timetable': 'Piga picha ratiba yako',
    };
    switch (lang.flavor) {
      case 'swahili':
      case 'sheng':
        return swahili[widget.intent] ?? 'Weka stakabadhi katikati ya fremu';
      default:
        return english[widget.intent] ?? 'Center your document in the frame';
    }
  }

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (!mounted) return;
      if (file == null) {
        // User cancelled — return to whatever launched the capture flow.
        setState(() => _busy = false);
        context.pop();
        return;
      }
      context.pushReplacement(
        '/scan/review?path=${Uri.encodeComponent(file.path)}&intent=${widget.intent}',
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final t = ref.l10n;
    final accent = TCC.agentColor(widget.intent) == TCC.textMuted
        ? TCC.accent
        : TCC.agentColor(widget.intent);
    return Scaffold(
      backgroundColor: TCC.bg,
      body: Stack(
        children: [
          // Viewfinder framing.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 96, 28, 220),
              child: _Viewfinder(color: accent),
            ),
          ),
          // Top bar.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: TCC.text, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
          // Hint text.
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + 56,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: TCC.surface2.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: TCC.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_strong_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Text(_hint(lang),
                        style: const TextStyle(
                            color: TCC.text, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          // Bottom controls.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery.
                    _RoundBtn(
                      icon: Icons.photo_library_rounded,
                      label: t.gallery,
                      onTap: _busy ? null : () => _capture(ImageSource.gallery),
                    ),
                    // Shutter.
                    GestureDetector(
                      onTap: _busy ? null : () => _capture(ImageSource.camera),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 4),
                          boxShadow: glow(accent, blur: 20, opacity: 0.5),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: _busy
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3, color: Colors.black),
                                )
                              : const Icon(Icons.camera_alt_rounded,
                                  color: Colors.black, size: 30),
                        ),
                      ),
                    ),
                    // Spacer to balance the shutter visually.
                    const SizedBox(width: 56),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: TCC.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: TCC.border),
              ),
              child: Icon(icon, color: TCC.text, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: TCC.textMuted, fontSize: 11)),
      ],
    );
  }
}

/// Corner-bracket viewfinder frame.
class _Viewfinder extends StatelessWidget {
  final Color color;
  const _Viewfinder({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ViewfinderPainter(color));
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  _ViewfinderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 34.0;
    const r = 6.0;
    // Top-left.
    canvas.drawLine(Offset(0, len), Offset(0, r), p);
    canvas.drawLine(Offset(r, 0), Offset(len, 0), p);
    // Top-right.
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), p);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), p);
    // Bottom-left.
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), p);
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), p);
    // Bottom-right.
    canvas.drawLine(
        Offset(size.width - len, size.height), Offset(size.width - r, size.height), p);
    canvas.drawLine(
        Offset(size.width, size.height - len), Offset(size.width, size.height - r), p);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter old) => old.color != color;
}
