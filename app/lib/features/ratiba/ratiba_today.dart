import 'dart:async';

import 'package:drift/drift.dart' show Value, OrderingTerm, OrderingMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P24 — Ratiba "Today": the planner home tab.
///
/// Reactive: composes three live drift streams (today's timetable classes,
/// nearest deadlines, open tasks) into one day view with an AI plan card,
/// a vertical timeline, quick links and a quick-add FAB.
class RatibaToday extends ConsumerWidget {
  const RatibaToday({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final lang = ref.watch(langProvider);

    return TccScaffold(
      showBack: false,
      title: lang.flavor == 'english' ? 'Schedule' : (lang.flavor == 'sheng' ? 'Ratiba' : 'Ratiba'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ratiba/tasks/edit'),
        backgroundColor: TCC.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          lang.flavor == 'english' ? 'Task' : 'Kazi',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<_RatibaData>(
        stream: _watchDay(db),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: TCC.accent),
            );
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              _header(context, lang),
              const SizedBox(height: 20),
              _DayPlanCard(summary: data.isEmpty ? null : _summaryLine(data, lang)),
              const SizedBox(height: 20),
              _quickLinks(context, lang),
              const SizedBox(height: 24),
              if (data.isEmpty)
                _emptyBody(context, lang)
              else
                _timeline(context, ref, data, lang),
            ],
          );
        },
      ),
    );
  }

  // ---- data ----

  Stream<_RatibaData> _watchDay(AppDatabase db) {
    final weekday = DateTime.now().weekday;
    final classes = (db.select(db.timetableClasses)
          ..where((c) => c.weekday.equals(weekday))
          ..orderBy([(c) => OrderingTerm(expression: c.startTime)]))
        .watch();
    final tasks = (db.select(db.tasks)
          ..where((t) => t.done.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
          ]))
        .watch();
    final deadlines = (db.select(db.deadlines)
          ..orderBy([(d) => OrderingTerm(expression: d.dueAt)]))
        .watch();
    return _combine3(classes, tasks, deadlines,
        (c, t, d) => _RatibaData(classes: c, tasks: t, deadlines: d));
  }

  String _summaryLine(_RatibaData d, LangPref lang) {
    final parts = <String>[];
    parts.add('${d.classes.length} '
        '${d.classes.length == 1 ? (lang.flavor == 'english' ? 'class' : 'darasani') : (lang.flavor == 'english' ? 'classes' : 'madarasa')}');
    final next = d.nearestDeadline;
    if (next != null) {
      final days = _daysUntil(next.dueAt);
      parts.add('${d.deadlines.length} '
          '${d.deadlines.length == 1 ? (lang.flavor == 'english' ? 'deadline' : 'mwisho') : (lang.flavor == 'english' ? 'deadlines' : 'tarehe za mwisho')} '
          '(${next.title}, ${_sikuLabel(days, lang)})');
    }
    parts.add('${d.tasks.length} '
        '${d.tasks.length == 1 ? (lang.flavor == 'english' ? 'task' : 'kazi') : (lang.flavor == 'english' ? 'tasks' : 'kazi')}');
    final summary = parts.join(', ');
    return switch (lang.flavor) {
      'swahili' => 'Siku yako: $summary.',
      'sheng' => 'Siku yako: $summary.',
      _ => "Here's your day ahead: $summary.",
    };
  }

  // ---- pieces ----

  Widget _header(BuildContext context, LangPref lang) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMM').format(now),
          style: const TextStyle(
            color: TCC.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(_greeting(now.hour, lang),
            style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _quickLinks(BuildContext context, LangPref lang) {
    final links = [
      (lang.flavor == 'english' ? 'Tasks' : 'Kazi', Icons.checklist_rounded, '/ratiba/tasks'),
      (lang.flavor == 'english' ? 'Deadlines' : 'Muda', Icons.flag_rounded, '/ratiba/deadlines'),
      (lang.flavor == 'english' ? 'Timetable' : 'Ratiba', Icons.grid_view_rounded, '/ratiba/timetable'),
    ];
    return Row(
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: TccCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              onTap: () => context.push(links[i].$3),
              child: Column(
                children: [
                  Icon(links[i].$2, color: TCC.accent, size: 22),
                  const SizedBox(height: 8),
                  Text(links[i].$1,
                      style: const TextStyle(
                          color: TCC.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyBody(BuildContext context, LangPref lang) {
    return EmptyState(
      icon: Icons.event_available_rounded,
      title: lang.flavor == 'english' ? 'No timetable yet — import one' : 'Bado huna ratiba — ingiza moja',
      subtitle: lang.flavor == 'english'
          ? 'Add your classes, tasks and deadlines to see your day here.'
          : 'Weka madarasa yako, kazi na tarehe za mwisho ili uone siku yako hapa.',
      action: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: TCC.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => context.push('/ratiba/timetable'),
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(
                lang.flavor == 'english' ? 'Import timetable' : 'Ingiza ratiba',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: TCC.text,
                side: const BorderSide(color: TCC.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => context.push('/ratiba/tasks/edit'),
              icon: const Icon(Icons.add_rounded),
              label: Text(lang.flavor == 'english' ? 'Add a task' : 'Weka kazi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, WidgetRef ref, _RatibaData d, LangPref lang) {
    final children = <Widget>[];

    if (d.classes.isNotEmpty) {
      children.add(SectionHeader(lang.flavor == 'english' ? 'Classes today' : 'Leo darasani'));
      for (final c in d.classes) {
        children.add(_classBlock(c));
        children.add(const SizedBox(height: 10));
      }
      children.add(const SizedBox(height: 12));
    }

    if (d.deadlines.isNotEmpty) {
      children.add(SectionHeader(switch (lang.flavor) {
        'swahili' => 'Makataa',
        _ => 'Deadlines',
      }));
      children.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final dl in d.deadlines.take(4)) _deadlinePill(dl, lang)],
      ));
      children.add(const SizedBox(height: 20));
    }

    if (d.tasks.isNotEmpty) {
      children.add(SectionHeader(
        lang.flavor == 'english' ? 'Tasks' : 'Kazi',
        trailing: TextButton(
          onPressed: () => context.push('/ratiba/tasks'),
          child: Text(lang.flavor == 'english' ? 'All' : 'Zote'),
        ),
      ));
      for (final t in d.tasks.take(6)) {
        children.add(_taskRow(context, ref, t, lang));
        children.add(const SizedBox(height: 8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _classBlock(TimetableClassesData c) {
    final color = _unitColor(c.unit);
    return TccCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.unit,
                    style: const TextStyle(
                        color: TCC.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (c.venue != null && c.venue!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 13, color: TCC.textMuted),
                      const SizedBox(width: 4),
                      Text(c.venue!,
                          style: const TextStyle(
                              color: TCC.textMuted, fontSize: 12.5)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${c.startTime}–${c.endTime}',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _deadlinePill(Deadline dl, LangPref lang) {
    final days = _daysUntil(dl.dueAt);
    final urgent = dl.dueAt.difference(DateTime.now()).inHours < 48;
    final color = urgent ? TCC.danger : TCC.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(dl.title,
              style: const TextStyle(
                  color: TCC.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(_sikuLabel(days, lang),
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _taskRow(BuildContext context, WidgetRef ref, Task t, LangPref lang) {
    return TccCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () async {
        final db = ref.read(dbProvider);
        await (db.update(db.tasks)..where((r) => r.id.equals(t.id)))
            .write(const TasksCompanion(done: Value(true)));
        if (context.mounted) {
          poa(
            context,
            switch (lang.flavor) {
              'swahili' => 'Poa! Kazi imekamilika',
              'sheng' => 'Poa! Task imemaliza',
              _ => 'Task completed',
            },
          );
        }
      },
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: TCC.textMuted, width: 1.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.title,
                style: const TextStyle(color: TCC.text, fontSize: 14.5)),
          ),
          _priorityDot(t.priority),
          if (t.dueAt != null) ...[
            const SizedBox(width: 10),
            Text(DateFormat('d MMM').format(t.dueAt!),
                style: const TextStyle(color: TCC.textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _priorityDot(int priority) {
    final color = switch (priority) {
      2 => TCC.danger,
      1 => TCC.warning,
      _ => TCC.textMuted,
    };
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// The AI plan card at the top of Ratiba. Shows the computed [summary] when the
/// day has content; otherwise offers a "Generate day plan" action that streams
/// Gemma output into the card.
class _DayPlanCard extends ConsumerStatefulWidget {
  final String? summary;
  const _DayPlanCard({this.summary});

  @override
  ConsumerState<_DayPlanCard> createState() => _DayPlanCardState();
}

class _DayPlanCardState extends ConsumerState<_DayPlanCard> {
  String _generated = '';
  bool _generating = false;

  Future<void> _generate() async {
    final lang = ref.read(langProvider);
    setState(() {
      _generating = true;
      _generated = '';
    });
    final gemma = ref.read(gemmaProvider);
    final buffer = StringBuffer();
    final prompt = lang.flavor == 'english'
        ? 'Plan my day today. I have classes, tasks, and deadlines.'
        : 'Panga siku yangu ya leo. Nina madarasa, tasks na deadlines.';

    await for (final token in gemma.chat(
      prompt,
      agent: 'ratiba',
    )) {
      buffer.write(token);
      if (mounted) setState(() => _generated = buffer.toString());
    }
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccCard(
      borderColor: TCC.accent.withValues(alpha: 0.55),
      shadow: glow(TCC.accent, opacity: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AgentAvatar('ratiba', size: 26),
              const SizedBox(width: 10),
              Text(lang.flavor == 'english' ? 'Schedule' : 'Ratiba',
                  style: const TextStyle(
                      color: TCC.ratiba,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TCC.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('AI plan',
                    style: TextStyle(
                        color: TCC.accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.summary != null)
            Text(widget.summary!,
                style: const TextStyle(
                    color: TCC.text, fontSize: 14.5, height: 1.5))
          else if (_generated.isNotEmpty)
            Text(_generated,
                style: const TextStyle(
                    color: TCC.text, fontSize: 14.5, height: 1.5))
          else
            Text(
              lang.flavor == 'english'
                  ? 'Nothing scheduled today. Want me to plan your day?'
                  : 'Hakuna kitu leo bado. Nikupangie siku?',
              style: const TextStyle(color: TCC.textMuted, fontSize: 14, height: 1.5),
            ),
          if (widget.summary == null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: TCC.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _generating ? null : _generate,
                icon: _generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  _generating
                      ? (lang.flavor == 'english' ? 'Planning...' : 'Inapanga…')
                      : (lang.flavor == 'english' ? 'Generate day plan' : 'Panga siku yangu'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---- shared helpers (file-local) ----

class _RatibaData {
  final List<TimetableClassesData> classes;
  final List<Task> tasks;
  final List<Deadline> deadlines;
  const _RatibaData({
    required this.classes,
    required this.tasks,
    required this.deadlines,
  });

  bool get isEmpty =>
      classes.isEmpty && tasks.isEmpty && deadlines.isEmpty;

  Deadline? get nearestDeadline =>
      deadlines.isEmpty ? null : deadlines.first;
}

String _greeting(int hour, LangPref lang) {
  if (lang.flavor == 'english') {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  } else if (lang.flavor == 'sheng') {
    if (hour < 12) return 'Niaje, asubuhi';
    if (hour < 17) return 'Sasa, mchana';
    return 'Niaje, jioni';
  } else {
    if (hour < 12) return 'Habari ya asubuhi';
    if (hour < 17) return 'Habari ya mchana';
    return 'Habari ya jioni';
  }
}

int _daysUntil(DateTime due) {
  final now = DateTime.now();
  final d = DateTime(due.year, due.month, due.day);
  final t = DateTime(now.year, now.month, now.day);
  return d.difference(t).inDays;
}

String _sikuLabel(int days, LangPref lang) {
  if (lang.flavor == 'english') {
    if (days < 0) return 'past due';
    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    return '$days days left';
  } else {
    if (days < 0) return 'imepita';
    if (days == 0) return 'leo';
    if (days == 1) return 'kesho';
    return 'siku $days';
  }
}

Color _unitColor(String unit) {
  const palette = [
    TCC.accent,
    TCC.primary,
    TCC.hustle,
    TCC.karani,
    Color(0xFF5B8DEF),
    Color(0xFFEF5B9C),
  ];
  return palette[unit.hashCode.abs() % palette.length];
}

/// Dependency-free combineLatest for three streams. Emits once all three have
/// produced at least one value, then on every subsequent change.
Stream<R> _combine3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combiner,
) {
  late final StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  var ha = false, hb = false, hc = false;
  StreamSubscription<A>? sa;
  StreamSubscription<B>? sb;
  StreamSubscription<C>? sc;

  void emit() {
    if (ha && hb && hc) controller.add(combiner(va as A, vb as B, vc as C));
  }

  controller = StreamController<R>(
    onListen: () {
      sa = a.listen((v) {
        va = v;
        ha = true;
        emit();
      }, onError: controller.addError);
      sb = b.listen((v) {
        vb = v;
        hb = true;
        emit();
      }, onError: controller.addError);
      sc = c.listen((v) {
        vc = v;
        hc = true;
        emit();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await sa?.cancel();
      await sb?.cancel();
      await sc?.cancel();
    },
  );
  return controller.stream;
}
