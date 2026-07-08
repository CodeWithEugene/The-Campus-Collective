import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P28 — deadlines, nearest first, overdue pinned to the top.
class DeadlineListScreen extends ConsumerWidget {
  const DeadlineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final lang = ref.watch(langProvider);

    return TccScaffold(
      title: lang.flavor == 'english' ? 'Deadlines' : 'Muda wa Mwisho',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref, lang),
        backgroundColor: TCC.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          lang.flavor == 'english' ? 'Manual deadline' : 'Muda wa mwongozo',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<Deadline>>(
        stream: (db.select(db.deadlines)
              ..orderBy([(d) => OrderingTerm(expression: d.dueAt)]))
            .watch(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: TCC.accent));
          }
          final all = snap.data!;
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: lang.flavor == 'english' ? 'No deadlines' : 'Hakuna muda wa mwisho',
              subtitle: lang.flavor == 'english'
                  ? 'Scanned documents and timetables drop deadlines here — or add one manually.'
                  : 'Nyaraka zilizopigwa picha na ratiba huweka muda wa mwisho hapa — au ongeza kwa mkono.',
            );
          }
          final now = DateTime.now();
          final overdue = all.where((d) => d.dueAt.isBefore(now)).toList();
          final upcoming = all.where((d) => !d.dueAt.isBefore(now)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              if (overdue.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: SectionHeader(lang.flavor == 'english' ? 'Overdue' : 'Zimepita muda'),
                ),
                for (final d in overdue) _row(d, overdue: true, lang: lang),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: SectionHeader(lang.flavor == 'english' ? 'Upcoming' : 'Zijazo'),
                ),
                for (final d in upcoming) _row(d, overdue: false, lang: lang),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(Deadline d, {required bool overdue, required LangPref lang}) {
    final hours = d.dueAt.difference(DateTime.now()).inHours;
    final urgent = !overdue && hours < 48;
    final chipColor = overdue ? TCC.danger : (urgent ? TCC.danger : TCC.warning);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TccCard(
        borderColor: overdue ? TCC.danger.withValues(alpha: 0.5) : null,
        color: overdue ? TCC.danger.withValues(alpha: 0.06) : null,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.flag_rounded, color: chipColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.title,
                      style: const TextStyle(
                          color: TCC.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _sourceBadge(d.sourceType, lang),
                      const SizedBox(width: 8),
                      Text(DateFormat('d MMM · HH:mm').format(d.dueAt),
                          style: const TextStyle(
                              color: TCC.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _countdownChip(d.dueAt, overdue, lang),
          ],
        ),
      ),
    );
  }

  Widget _sourceBadge(String sourceType, LangPref lang) {
    final (label, color) = switch (sourceType) {
      'scan' => (lang.flavor == 'english' ? 'From scan' : 'Kutoka scan', TCC.primary),
      'timetable' => (lang.flavor == 'english' ? 'Timetable' : 'Ratiba', TCC.accent),
      _ => (lang.flavor == 'english' ? 'Manual' : 'Mwongozo', TCC.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _countdownChip(DateTime due, bool overdue, LangPref lang) {
    final now = DateTime.now();
    final urgent = !overdue && due.difference(now).inHours < 48;
    final color = overdue || urgent ? TCC.danger : TCC.warning;
    final label = overdue ? (lang.flavor == 'english' ? 'past due' : 'imepita') : _sikuLabel(_daysUntil(due), lang);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref, LangPref lang) async {
    final titleCtrl = TextEditingController();
    DateTime picked = DateTime.now().add(const Duration(days: 1));

    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          backgroundColor: TCC.surface,
          title: Text(lang.flavor == 'english' ? 'New deadline' : 'Mwisho mpya'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: lang.flavor == 'english' ? 'e.g. HELB application' : 'mf. Fomu ya HELB',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(TCC.radiusSm),
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: c,
                    initialDate: picked,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: DateTime(now.year + 3),
                  );
                  if (date == null) return;
                  if (!c.mounted) return;
                  final time = await showTimePicker(
                    context: c,
                    initialTime: TimeOfDay.fromDateTime(picked),
                  );
                  setDialog(() => picked = DateTime(date.year, date.month,
                      date.day, time?.hour ?? 23, time?.minute ?? 59));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: TCC.surface2,
                    borderRadius: BorderRadius.circular(TCC.radiusSm),
                    border: Border.all(color: TCC.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: TCC.accent),
                      const SizedBox(width: 10),
                      Text(DateFormat('EEE, d MMM · HH:mm').format(picked),
                          style: const TextStyle(
                              color: TCC.text, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(lang.flavor == 'english' ? 'Cancel' : 'Ghairi')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: TCC.accent, foregroundColor: Colors.black),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final db = ref.read(dbProvider);
                await db.into(db.deadlines).insert(DeadlinesCompanion.insert(
                      title: title,
                      dueAt: picked,
                      sourceType: const Value('manual'),
                    ));
                if (!c.mounted) return;
                Navigator.pop(c);
                if (context.mounted) {
                  poa(context, lang.flavor == 'english' ? 'Deadline added successfully!' : 'Poa! Deadline imeongezwa');
                }
              },
              child: Text(lang.flavor == 'english' ? 'Add' : 'Weka'),
            ),
          ],
        ),
      ),
    );
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
