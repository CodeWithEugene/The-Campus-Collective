import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P10 — Somo study results: summary, quiz teaser, flashcard teaser.
class SomoResultScreen extends ConsumerStatefulWidget {
  final String? scanId;
  const SomoResultScreen({super.key, this.scanId});

  @override
  ConsumerState<SomoResultScreen> createState() => _SomoResultScreenState();
}

class _SomoResultScreenState extends ConsumerState<SomoResultScreen> {
  late Future<Map<String, dynamic>> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final id = int.tryParse(widget.scanId ?? '');
    if (id != null) {
      final db = ref.read(dbProvider);
      final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null) {
        return jsonDecode(row.resultJson) as Map<String, dynamic>;
      }
    }
    return ref.read(gemmaProvider).structured('Study these notes', schemaHint: 'quiz');
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: lang.flavor == 'english' ? 'Study' : 'Somo',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (c, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: TCC.accent),
            );
          }
          final data = snap.data!;
          final summary = (data['summary'] as List?)?.cast<dynamic>() ?? const [];
          final simple = data['simple'] as String? ?? '';
          final quiz = (data['quiz'] as List?)?.cast<dynamic>() ?? const [];
          final cards = (data['flashcards'] as List?)?.cast<dynamic>() ?? const [];

          if (summary.isEmpty && quiz.isEmpty && cards.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_rounded,
              title: lang.flavor == 'english' ? 'Nothing to study yet' : 'Hakuna cha kusoma bado',
              subtitle: lang.flavor == 'english'
                  ? 'The photo did not have enough text. Try taking it again.'
                  : 'Picha haikuwa na maandishi ya kutosha. Jaribu kupiga tena.',
              action: FilledButton(
                onPressed: () => context.go('/scan/camera?intent=somo'),
                child: Text(L(lang.flavor).takeAgain),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _Segmented(
                  index: _tab,
                  labels: [
                    L(lang.flavor).summary,
                    L(lang.flavor).quiz,
                    L(lang.flavor).cards,
                  ],
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _summaryTab(summary, simple, lang),
                    _quizTab(quiz.length, lang),
                    _cardsTab(cards.length, lang),
                  ],
                ),
              ),
              _shareBar(data, lang),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryTab(List<dynamic> summary, String simple, LangPref lang) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        SectionHeader(L(lang.flavor).keyPoints),
        ...summary.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: TCC.somo, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('$s',
                        style: const TextStyle(color: TCC.text, fontSize: 15, height: 1.4)),
                  ),
                ],
              ),
            )),
        if (simple.isNotEmpty) ...[
          const SizedBox(height: 8),
          TccCard(
            color: TCC.somo.withValues(alpha: 0.08),
            borderColor: TCC.somo.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: TCC.somo, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${L(lang.flavor).inSimpleTerms}:',
                      style: const TextStyle(
                          color: TCC.somo, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(simple,
                    style: const TextStyle(color: TCC.text, fontSize: 15, height: 1.45)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _quizTab(int count, LangPref lang) {
    return _TeaserTab(
      icon: Icons.quiz_rounded,
      title: lang.flavor == 'english'
          ? '$count ${count == 1 ? "question" : "questions"} ready'
          : '$count ${count == 1 ? "swali" : "maswali"} tayari',
      subtitle: lang.flavor == 'english'
          ? 'Test yourself to see if you understood your notes.'
          : 'Jitest uone kama umeelewa notes zako.',
      cta: lang.flavor == 'english' ? 'Start Quiz' : 'Anza Quiz',
      onTap: () => context.push('/somo/quiz?id=${widget.scanId ?? ''}'),
    );
  }

  Widget _cardsTab(int count, LangPref lang) {
    return _TeaserTab(
      icon: Icons.style_rounded,
      title: '$count flashcards',
      subtitle: lang.flavor == 'english'
          ? 'Flip cards to remember key concepts.'
          : 'Geuza kadi kukumbuka maneno muhimu.',
      cta: lang.flavor == 'english' ? 'View Flashcards' : 'Ona Flashcards',
      onTap: () => context.push('/somo/flashcards?id=${widget.scanId ?? ''}'),
    );
  }

  Widget _shareBar(Map<String, dynamic> data, LangPref lang) {
    final summary = (data['summary'] as List?)?.cast<dynamic>() ?? const [];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: TCC.bg,
        border: Border(top: BorderSide(color: TCC.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => context.push('/somo/quiz?id=${widget.scanId ?? ''}'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(lang.flavor == 'english' ? 'Start Quiz' : 'Anza Quiz'),
                style: FilledButton.styleFrom(
                  backgroundColor: TCC.accent,
                  foregroundColor: Colors.black,
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
              onPressed: () {
                final heading = lang.flavor == 'english'
                    ? 'My study summary:'
                    : 'Muhtasari wa somo langu:';
                Share.share(
                  '$heading\n\n${summary.map((s) => "• $s").join("\n")}\n\n— via TCC',
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: TCC.border),
              ),
              child: const Icon(Icons.ios_share_rounded, color: TCC.text, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeaserTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;
  const _TeaserTab({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TccCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: TCC.somo.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: TCC.somo, size: 30),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: TCC.text, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TCC.textMuted, fontSize: 14, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: TCC.somo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: Text(cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill segmented control.
class _Segmented extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.index, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TCC.surface2,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TCC.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? TCC.somo : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: sel ? Colors.white : TCC.textMuted,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
