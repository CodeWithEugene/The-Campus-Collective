import 'package:drift/drift.dart' show Value, OrderingTerm, OrderingMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P26 — the full task list with filters, date sections and swipe actions.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

enum _Filter { all, today, upcoming, done }

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final db = ref.read(dbProvider);
    final lang = ref.watch(langProvider);

    return TccScaffold(
      title: lang.flavor == 'english' ? 'Tasks' : 'Kazi',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ratiba/tasks/edit'),
        backgroundColor: TCC.accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          _filterBar(lang),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: (db.select(db.tasks)
                    ..orderBy([
                      (t) => OrderingTerm(expression: t.dueAt),
                      (t) => OrderingTerm(
                          expression: t.priority, mode: OrderingMode.desc),
                    ]))
                  .watch(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: TCC.accent));
                }
                final tasks = _apply(snap.data!);
                if (tasks.isEmpty) {
                  return EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: lang.flavor == 'english' ? 'No tasks — you\'re free!' : 'Hakuna kazi — uko huru!',
                    subtitle: lang.flavor == 'english'
                        ? 'Tap + to add something to your plan.'
                        : 'Gusa + ili kuongeza jambo kwenye mpango wako.',
                  );
                }
                return _grouped(tasks, lang);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- filtering ----

  List<Task> _apply(List<Task> all) {
    switch (_filter) {
      case _Filter.all:
        return all.where((t) => !t.done).toList();
      case _Filter.done:
        return all.where((t) => t.done).toList();
      case _Filter.today:
        return all
            .where((t) => !t.done && t.dueAt != null && _isToday(t.dueAt!))
            .toList();
      case _Filter.upcoming:
        final now = DateTime.now();
        return all
            .where((t) =>
                !t.done &&
                t.dueAt != null &&
                t.dueAt!.isAfter(now) &&
                !_isToday(t.dueAt!))
            .toList();
    }
  }

  Widget _filterBar(LangPref lang) {
    final items = [
      (_Filter.all, lang.flavor == 'english' ? 'All' : 'Zote'),
      (_Filter.today, lang.flavor == 'english' ? 'Today' : 'Leo'),
      (_Filter.upcoming, lang.flavor == 'english' ? 'Upcoming' : 'Zijazo'),
      (_Filter.done, lang.flavor == 'english' ? 'Done' : 'Zilizokamilika'),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final it in items) ...[
            TccChip(
              label: it.$2,
              selected: _filter == it.$1,
              onTap: () => setState(() => _filter = it.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // ---- grouped list ----

  Widget _grouped(List<Task> tasks, LangPref lang) {
    final groups = <String, List<Task>>{};
    for (final t in tasks) {
      groups.putIfAbsent(_sectionFor(t, lang), () => []).add(t);
    }
    final children = <Widget>[];
    groups.forEach((label, list) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: SectionHeader(label),
      ));
      for (final t in list) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _taskTile(t, lang),
        ));
      }
    });
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: children,
    );
  }

  String _sectionFor(Task t, LangPref lang) {
    if (lang.flavor == 'english') {
      if (t.done) return 'Completed';
      if (t.dueAt == null) return 'No due date';
      final days = _daysUntil(t.dueAt!);
      if (days < 0) return 'Overdue';
      if (days == 0) return 'Today';
      if (days == 1) return 'Tomorrow';
      if (days <= 7) return 'This week';
      return 'Later';
    } else {
      if (t.done) return 'Zilizokamilika';
      if (t.dueAt == null) return 'Hazina tarehe';
      final days = _daysUntil(t.dueAt!);
      if (days < 0) return 'Zimepita muda';
      if (days == 0) return 'Leo';
      if (days == 1) return 'Kesho';
      if (days <= 7) return 'Wiki hii';
      return 'Baadaye';
    }
  }

  Widget _taskTile(Task t, LangPref lang) {
    return Dismissible(
      key: ValueKey('task-${t.id}'),
      background: _swipeBg(
          Alignment.centerLeft, TCC.accent, Icons.check_rounded, 'Done', lang),
      secondaryBackground: _swipeBg(
          Alignment.centerRight, TCC.danger, Icons.delete_outline_rounded,
          'Delete', lang),
      confirmDismiss: (dir) async {
        final db = ref.read(dbProvider);
        if (dir == DismissDirection.startToEnd) {
          await (db.update(db.tasks)..where((r) => r.id.equals(t.id)))
              .write(TasksCompanion(done: Value(!t.done)));
          if (mounted) {
            poa(context, t.done
                ? (lang.flavor == 'english' ? 'Reopened' : 'Imefunguliwa tena')
                : (lang.flavor == 'english' ? 'Saved successfully!' : 'Poa! Kazi imekamilika'));
          }
          return false; // keep row; stream reflects state
        } else {
          await (db.delete(db.tasks)..where((r) => r.id.equals(t.id))).go();
          if (mounted) poa(context, lang.flavor == 'english' ? 'Task deleted' : 'Kazi imefutwa');
          return true;
        }
      },
      child: TccCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => context.push('/ratiba/tasks/edit?id=${t.id}'),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                final db = ref.read(dbProvider);
                await (db.update(db.tasks)..where((r) => r.id.equals(t.id)))
                    .write(TasksCompanion(done: Value(!t.done)));
                if (mounted && !t.done) {
                  poa(context, lang.flavor == 'english' ? 'Saved successfully!' : 'Poa! Kazi imekamilika');
                }
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.done ? TCC.accent : Colors.transparent,
                  border: Border.all(
                      color: t.done ? TCC.accent : TCC.textMuted, width: 1.6),
                ),
                child: t.done
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: TextStyle(
                      color: t.done ? TCC.textMuted : TCC.text,
                      fontSize: 14.5,
                      decoration:
                          t.done ? TextDecoration.lineThrough : null,
                      decorationColor: TCC.textMuted,
                    ),
                  ),
                  if (t.dueAt != null) ...[
                    const SizedBox(height: 4),
                    _dueChip(t.dueAt!, t.done),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _priorityDot(t.priority),
          ],
        ),
      ),
    );
  }

  Widget _dueChip(DateTime due, bool done) {
    final overdue = !done && due.isBefore(DateTime.now());
    final color = overdue ? TCC.danger : TCC.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(DateFormat('d MMM · HH:mm').format(due),
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _swipeBg(
      Alignment align, Color color, IconData icon, String label, LangPref lang) {
    final leading = align == Alignment.centerLeft;
    final displayLabel = label == 'Done'
        ? (lang.flavor == 'english' ? 'Done' : 'Kamilisha')
        : (lang.flavor == 'english' ? 'Delete' : 'Futa');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: align,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(TCC.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
          ],
          Text(displayLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          if (!leading) ...[
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 20),
          ],
        ],
      ),
    );
  }
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

int _daysUntil(DateTime due) {
  final now = DateTime.now();
  final d = DateTime(due.year, due.month, due.day);
  final t = DateTime(now.year, now.month, now.day);
  return d.difference(t).inDays;
}
