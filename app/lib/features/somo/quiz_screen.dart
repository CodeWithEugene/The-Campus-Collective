import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P11 — one-question-at-a-time quiz with instant feedback + results.
class QuizScreen extends ConsumerStatefulWidget {
  final String? scanId;
  const QuizScreen({super.key, this.scanId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late Future<List<_Q>> _future;

  List<_Q> _questions = [];
  int _index = 0;
  int? _picked;
  bool _revealed = false;
  final List<int?> _answers = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Q>> _load() async {
    Map<String, dynamic>? data;
    final id = int.tryParse(widget.scanId ?? '');
    if (id != null) {
      final db = ref.read(dbProvider);
      final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null) data = jsonDecode(row.resultJson) as Map<String, dynamic>;
    }
    data ??= await ref.read(gemmaProvider).structured('Quiz me', schemaHint: 'quiz');

    final raw = (data['quiz'] as List?)?.cast<dynamic>() ?? const [];
    final qs = raw
        .map((e) => _Q(
              q: e['q'] as String? ?? '',
              options: (e['options'] as List?)?.map((o) => '$o').toList() ?? const [],
              answer: (e['answer'] as num?)?.toInt() ?? 0,
              why: e['why'] as String? ?? '',
            ))
        .where((q) => q.options.isNotEmpty)
        .toList();
    _questions = qs;
    _answers
      ..clear()
      ..addAll(List<int?>.filled(qs.length, null));
    return qs;
  }

  void _pick(int i) {
    if (_revealed) return;
    setState(() {
      _picked = i;
      _revealed = true;
      _answers[_index] = i;
    });
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      setState(() => _done = true);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _revealed = false;
    });
  }

  int get _score {
    var s = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].answer) s++;
    }
    return s;
  }

  void _restart() {
    setState(() {
      _index = 0;
      _picked = null;
      _revealed = false;
      _done = false;
      for (var i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: 'Quiz',
      body: FutureBuilder<List<_Q>>(
        future: _future,
        builder: (c, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: TCC.accent));
          }
          if (_questions.isEmpty) {
            return EmptyState(
              icon: Icons.quiz_outlined,
              title: lang.flavor == 'english' ? 'No questions' : 'Hakuna maswali',
              subtitle: lang.flavor == 'english'
                  ? 'Notes did not have enough content to generate a quiz.'
                  : 'Notes hazikuwa na cha kutosha kutengeneza quiz.',
              action: FilledButton(
                onPressed: () => context.go('/chat'),
                child: Text(lang.flavor == 'english' ? 'Back to chat' : 'Rudi kwa chat'),
              ),
            );
          }
          return _done ? _results(lang) : _question(lang);
        },
      ),
    );
  }

  Widget _question(LangPref lang) {
    final q = _questions[_index];
    return Column(
      children: [
        // Progress.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.flavor == 'english'
                    ? 'Question ${_index + 1}/${_questions.length}'
                    : 'Swali ${_index + 1}/${_questions.length}',
                style: const TextStyle(
                    color: TCC.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _questions.length,
                  minHeight: 6,
                  backgroundColor: TCC.surface2,
                  valueColor: const AlwaysStoppedAnimation(TCC.accent),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Text(q.q,
                  style: const TextStyle(
                      color: TCC.text, fontSize: 20, fontWeight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 20),
              ...List.generate(q.options.length, (i) => _option(q, i)),
              if (_revealed && q.why.isNotEmpty) ...[
                const SizedBox(height: 8),
                TccCard(
                  color: TCC.surface2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: TCC.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: TCC.text, fontSize: 14, height: 1.4),
                            children: [
                              TextSpan(
                                  text: lang.flavor == 'english' ? 'Why: ' : 'Kwa nini: ',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: q.why),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_revealed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: TCC.accent,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: Text(
                  _index >= _questions.length - 1
                      ? (lang.flavor == 'english' ? 'Show results' : 'Ona matokeo')
                      : (lang.flavor == 'english' ? 'Continue' : 'Endelea'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _option(_Q q, int i) {
    Color border = TCC.border;
    Color bg = TCC.surface;
    Color fg = TCC.text;
    IconData? trailing;
    Color trailingColor = TCC.accent;

    if (_revealed) {
      if (i == q.answer) {
        border = TCC.accent;
        bg = TCC.accent.withValues(alpha: 0.12);
        trailing = Icons.check_circle_rounded;
        trailingColor = TCC.accent;
      } else if (i == _picked) {
        border = TCC.danger;
        bg = TCC.danger.withValues(alpha: 0.12);
        trailing = Icons.cancel_rounded;
        trailingColor = TCC.danger;
      } else {
        fg = TCC.textMuted;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pick(i),
          borderRadius: BorderRadius.circular(TCC.radius),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(TCC.radius),
              border: Border.all(color: border, width: border == TCC.border ? 1 : 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: border == TCC.border ? TCC.textMuted : border),
                  ),
                  child: Text(String.fromCharCode(65 + i),
                      style: TextStyle(
                          color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(q.options[i],
                      style: TextStyle(color: fg, fontSize: 15, height: 1.35)),
                ),
                if (trailing != null) Icon(trailing, color: trailingColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(LangPref lang) {
    final total = _questions.length;
    final score = _score;
    final pct = score / total;
    final blurb = pct >= 0.8
        ? (lang.flavor == 'english' ? 'Great job! 🎉' : 'Poa sana! 🎉')
        : pct >= 0.5
            ? (lang.flavor == 'english' ? 'Good job! Keep learning.' : 'Poa! Endelea kusoma.')
            : (lang.flavor == 'english' ? 'Don\'t give up — review your notes.' : 'Usikate tamaa — rudia notes.');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        TccCard(
          padding: const EdgeInsets.all(26),
          borderColor: TCC.accent.withValues(alpha: 0.4),
          shadow: glow(TCC.accent, opacity: 0.2),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: TCC.accent, size: 44),
              const SizedBox(height: 14),
              Text(
                lang.flavor == 'english' ? 'You scored $score/$total — $blurb' : 'Umepata $score/$total — $blurb',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: TCC.text, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(lang.flavor == 'english' ? 'Review' : 'Mapitio'),
        ...List.generate(total, (i) {
          final q = _questions[i];
          final correct = _answers[i] == q.answer;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TccCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: correct ? TCC.accent : TCC.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(q.q,
                            style: const TextStyle(
                                color: TCC.text, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      lang.flavor == 'english' ? 'Correct answer: ${q.options[q.answer]}' : 'Jibu sahihi: ${q.options[q.answer]}',
                      style: const TextStyle(color: TCC.accent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: Text(lang.flavor == 'english' ? 'Restart' : 'Rudia'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TCC.somo,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              width: 50,
              child: OutlinedButton(
                onPressed: () =>
                    Share.share(lang.flavor == 'english'
                        ? 'I scored $score/$total on my TCC quiz! 🎓'
                        : 'Nimepata $score/$total kwenye quiz yangu ya TCC! 🎓'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: TCC.border),
                ),
                child: const Icon(Icons.ios_share_rounded, color: TCC.text, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: TCC.text),
            label: Text(lang.flavor == 'english' ? 'Back to chat' : 'Rudi kwa chat', style: const TextStyle(color: TCC.text)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: TCC.border)),
          ),
        ),
      ],
    );
  }
}

class _Q {
  final String q;
  final List<String> options;
  final int answer;
  final String why;
  _Q({required this.q, required this.options, required this.answer, required this.why});
}
