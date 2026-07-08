import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P12 — Flashcards screen. Spaced-repetition card decks with database loading.
class FlashcardScreen extends ConsumerStatefulWidget {
  final String? scanId;
  const FlashcardScreen({super.key, this.scanId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _index = 0;
  bool _front = true;
  bool _loading = true;
  bool _finished = false;

  List<_Card> _cards = [];
  final List<_Card> _retryPile = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _load();
  }

  Future<void> _load() async {
    final id = int.tryParse(widget.scanId ?? '');
    if (id != null) {
      try {
        final db = ref.read(dbProvider);
        final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (row != null) {
          final data = jsonDecode(row.resultJson) as Map<String, dynamic>;
          final list = data['flashcards'] as List?;
          if (list != null && list.isNotEmpty) {
            final parsed = list.map((item) {
              final map = item as Map<String, dynamic>;
              return _Card(
                front: map['front']?.toString() ?? '',
                back: map['back']?.toString() ?? '',
              );
            }).toList();
            setState(() {
              _cards = parsed;
              _loading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading cards: $e');
      }
    }
    // Fallback placeholder cards
    setState(() {
      _cards = const [
        _Card(front: 'What is the main idea?', back: 'The central concept being discussed.'),
        _Card(front: 'Key term one', back: 'Its definition and importance.'),
        _Card(front: 'Supporting fact A', back: 'Evidence that bolsters the main argument.'),
        _Card(front: 'Supporting fact B', back: 'Additional evidence from the text.'),
      ];
      _loading = false;
    });
  }

  void _flip() {
    if (_front) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    _front = !_front;
  }

  void _markAgain() {
    _retryPile.add(_cards[_index]);
    _nextCard();
  }

  void _markGood() {
    _nextCard();
  }

  void _nextCard() {
    if (_index < _cards.length - 1) {
      setState(() {
        _index++;
        _front = true;
        _ctrl.reset();
      });
    } else {
      setState(() {
        _finished = true;
      });
    }
  }

  void _startRetry() {
    setState(() {
      _cards = [..._retryPile];
      _retryPile.clear();
      _index = 0;
      _front = true;
      _finished = false;
      _ctrl.reset();
    });
  }

  void _restartAll() {
    _retryPile.clear();
    _load();
    setState(() {
      _index = 0;
      _front = true;
      _finished = false;
      _ctrl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);

    if (_loading) {
      return const TccScaffold(
        title: 'Flashcards',
        body: Center(
          child: CircularProgressIndicator(color: TCC.accent),
        ),
      );
    }

    Widget bodyContent;

    if (_finished) {
      if (_retryPile.isNotEmpty) {
        bodyContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style_rounded, color: TCC.accent, size: 56),
            const SizedBox(height: 18),
            Text(
              lang.flavor == 'english' ? 'Round Complete!' : 'Kadi Zote Zimeisha!',
              style: const TextStyle(color: TCC.text, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              lang.flavor == 'english'
                  ? 'You marked ${_retryPile.length} cards to review again.'
                  : 'Uliweka kadi ${_retryPile.length} za kurudia.',
              style: const TextStyle(color: TCC.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 48,
              child: FilledButton(
                onPressed: _startRetry,
                style: FilledButton.styleFrom(backgroundColor: TCC.somo),
                child: Text(lang.flavor == 'english' ? 'Review Retries' : 'Rudia Kadi'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _restartAll,
              child: Text(
                lang.flavor == 'english' ? 'Restart Entire Deck' : 'Anza Upya Zote',
                style: const TextStyle(color: TCC.textMuted),
              ),
            ),
          ],
        );
      } else {
        bodyContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, color: TCC.accent, size: 56),
            const SizedBox(height: 18),
            Text(
              lang.flavor == 'english' ? 'All Done! 🎉' : 'Umeweza Zote! 🎉',
              style: const TextStyle(color: TCC.text, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              lang.flavor == 'english'
                  ? 'Fantastic! You mastered every card in this deck.'
                  : 'Safi sana! Umeelewa kila kadi kwenye deck hii.',
              style: const TextStyle(color: TCC.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: FilledButton(
                onPressed: _restartAll,
                style: FilledButton.styleFrom(backgroundColor: TCC.accent, foregroundColor: Colors.black),
                child: Text(lang.flavor == 'english' ? 'Restart Deck' : 'Anza Upya'),
              ),
            ),
          ],
        );
      }
    } else {
      bodyContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Counter
          Text(
            '${_index + 1}/${_cards.length}',
            style: const TextStyle(color: TCC.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // Card
          GestureDetector(
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                final angle = _anim.value * 3.14159;
                final isFront = angle < 1.5708;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Container(
                    width: double.infinity,
                    height: 280,
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TCC.surface,
                      borderRadius: BorderRadius.circular(TCC.radiusLg),
                      border: Border.all(color: TCC.border),
                      boxShadow: glow(TCC.somo, blur: 16, opacity: 0.08),
                    ),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(isFront ? 0 : 3.14159),
                      child: Text(
                        isFront ? _cards[_index].front : _cards[_index].back,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: TCC.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Spaced-Repetition Interactive Panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _front
                ? SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _flip,
                      icon: const Icon(Icons.flip_rounded, size: 20),
                      label: Text(lang.flavor == 'english' ? 'Reveal Answer' : 'Onyesha Jibu'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TCC.border),
                        foregroundColor: TCC.accent,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _markAgain,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: TCC.danger),
                              foregroundColor: TCC.danger,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(TCC.radius),
                              ),
                            ),
                            child: Text(lang.flavor == 'english' ? 'Again' : 'Rudia tena'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _markGood,
                            style: FilledButton.styleFrom(
                              backgroundColor: TCC.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(TCC.radius),
                              ),
                            ),
                            child: Text(lang.flavor == 'english' ? 'Good' : 'Nimeelewa'),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }

    return TccScaffold(
      title: lang.flavor == 'english' ? 'Study Cards' : 'Kadi za Somo',
      actions: [
        IconButton(
          onPressed: () => context.go('/chat'),
          icon: const Icon(Icons.close_rounded, color: TCC.textMuted),
        ),
      ],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: bodyContent,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _Card {
  final String front;
  final String back;
  const _Card({required this.front, required this.back});
}
