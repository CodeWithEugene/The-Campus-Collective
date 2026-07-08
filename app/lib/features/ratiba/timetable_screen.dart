import 'dart:convert';
import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P29 — weekly timetable, one tab per weekday (Mon–Sat) / P30 — Timetable Import Confirm.
class TimetableScreen extends ConsumerStatefulWidget {
  final String? scanId;
  const TimetableScreen({super.key, this.scanId});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    if (widget.scanId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForImport());
    }
  }

  Future<void> _checkForImport() async {
    final db = ref.read(dbProvider);
    final scanIdVal = int.tryParse(widget.scanId ?? '');
    if (scanIdVal == null) return;

    final scan = await (db.select(db.scans)..where((s) => s.id.equals(scanIdVal))).getSingleOrNull();
    if (scan == null) return;

    try {
      final data = jsonDecode(scan.resultJson) as Map<String, dynamic>;
      final classes = data['classes'] as List?;
      if (classes == null || classes.isEmpty) return;

      if (!mounted) return;
      final lang = ref.read(langProvider);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: TCC.surface,
          title: Text(lang.flavor == 'english' ? 'Import Timetable?' : 'Ingiza Ratiba?'),
          content: Text(lang.flavor == 'english'
              ? 'Found ${classes.length} classes in your scan. Do you want to add them to your timetable?'
              : 'Imepata madarasa ${classes.length} kwenye scan yako. Je, ungependa kuyaongeza kwenye ratiba yako?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(lang.flavor == 'english' ? 'Cancel' : 'Ghairi')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: TCC.accent, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(c, true),
              child: Text(lang.flavor == 'english' ? 'Import' : 'Ingiza'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        for (final item in classes) {
          final map = item as Map<String, dynamic>;
          await db.into(db.timetableClasses).insert(
                TimetableClassesCompanion.insert(
                  unit: map['unit'].toString(),
                  weekday: (map['weekday'] as num).toInt(),
                  startTime: map['startTime'].toString(),
                  endTime: map['endTime'].toString(),
                  venue: Value(map['venue']?.toString()),
                  lecturer: Value(map['lecturer']?.toString()),
                ),
              );
        }
        if (mounted) poa(context, lang.flavor == 'english' ? 'Timetable imported successfully!' : 'Timetable imeingizwa!');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(dbProvider);
    final lang = ref.watch(langProvider);
    final initial = (DateTime.now().weekday - 1).clamp(0, 5);

    return DefaultTabController(
      length: _days.length,
      initialIndex: initial,
      child: TccScaffold(
        title: lang.flavor == 'english' ? 'Timetable' : 'Ratiba',
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: TCC.accent,
          labelColor: TCC.accent,
          unselectedLabelColor: TCC.textMuted,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: 'Mon'),
            Tab(text: 'Tue'),
            Tab(text: 'Wed'),
            Tab(text: 'Thu'),
            Tab(text: 'Fri'),
            Tab(text: 'Sat'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addClassDialog(context, lang),
          backgroundColor: TCC.accent,
          foregroundColor: Colors.black,
          child: const Icon(Icons.add_rounded),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<TimetableClassesData>>(
                stream: (db.select(db.timetableClasses)
                      ..orderBy(
                          [(c) => OrderingTerm(expression: c.startTime)]))
                    .watch(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: TCC.accent));
                  }
                  final all = snap.data!;
                  return TabBarView(
                    children: [
                      for (var day = 1; day <= 6; day++)
                        _dayView(
                          all.where((c) => c.weekday == day).toList(),
                          lang,
                        ),
                    ],
                  );
                },
              ),
            ),
            _importBar(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _dayView(List<TimetableClassesData> classes, LangPref lang) {
    if (classes.isEmpty) {
      return EmptyState(
        icon: Icons.grid_view_rounded,
        title: lang.flavor == 'english' ? 'Import your timetable from a photo' : 'Ingiza ratiba yako kutoka kwa picha',
        subtitle: lang.flavor == 'english' ? 'Or tap + to add a class for this day.' : 'Au gusa + ili kuongeza darasa la siku hii.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [for (final c in classes) _classCard(c)],
    );
  }

  Widget _classCard(TimetableClassesData c) {
    final color = _unitColor(c.unit);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _deleteClass(c),
        child: TccCard(
          borderColor: color.withValues(alpha: 0.4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
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
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: TCC.textMuted),
                        const SizedBox(width: 5),
                        Text('${c.startTime} – ${c.endTime}',
                            style: TextStyle(
                                color: color,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (c.venue != null && c.venue!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _metaRow(Icons.place_outlined, c.venue!),
                    ],
                    if (c.lecturer != null && c.lecturer!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _metaRow(Icons.person_outline_rounded, c.lecturer!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: TCC.textMuted),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(color: TCC.textMuted, fontSize: 12.5)),
      ],
    );
  }

  Widget _importBar(BuildContext context, LangPref lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: TCC.bg,
        border: Border(top: BorderSide(color: TCC.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: TCC.accent,
              side: BorderSide(color: TCC.accent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: () => context.push('/scan/camera?intent=timetable'),
            icon: const Icon(Icons.photo_camera_rounded, size: 18),
            label: Text(
              lang.flavor == 'english' ? 'Import timetable' : 'Ingiza ratiba',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClass(TimetableClassesData c) async {
    final lang = ref.read(langProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: TCC.surface,
        title: Text(lang.flavor == 'english' ? 'Delete ${c.unit}?' : 'Futa ${c.unit}?'),
        content: Text(lang.flavor == 'english' ? 'Remove this class from your timetable.' : 'Ondoa darasa hili kwenye ratiba yako.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dc, false),
              child: Text(lang.flavor == 'english' ? 'Cancel' : 'Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(dc, true),
            child: Text(lang.flavor == 'english' ? 'Delete' : 'Futa', style: const TextStyle(color: TCC.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(dbProvider);
    await (db.delete(db.timetableClasses)..where((r) => r.id.equals(c.id)))
        .go();
    if (mounted) poa(context, lang.flavor == 'english' ? 'Class removed' : 'Darasa limeondolewa');
  }

  Future<void> _addClassDialog(BuildContext context, LangPref lang) async {
    final unitCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    var weekday = DateTime.now().weekday.clamp(1, 6);
    var start = const TimeOfDay(hour: 8, minute: 0);
    var end = const TimeOfDay(hour: 10, minute: 0);

    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          backgroundColor: TCC.surface,
          title: Text(lang.flavor == 'english' ? 'Add class' : 'Weka darasa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: unitCtrl,
                  autofocus: true,
                  decoration: InputDecoration(hintText: lang.flavor == 'english' ? 'Unit / course' : 'Somo / kozi'),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lang.flavor == 'english' ? 'Day' : 'Siku',
                    style: const TextStyle(
                        color: TCC.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var d = 1; d <= 6; d++)
                      TccChip(
                        label: _days[d - 1],
                        selected: weekday == d,
                        onTap: () => setDialog(() => weekday = d),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _timeField(c, lang.flavor == 'english' ? 'Start' : 'Mwanzo', fmt(start), () async {
                        final t = await showTimePicker(
                            context: c, initialTime: start);
                        if (t != null) setDialog(() => start = t);
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _timeField(c, lang.flavor == 'english' ? 'End' : 'Mwisho', fmt(end), () async {
                        final t = await showTimePicker(
                            context: c, initialTime: end);
                        if (t != null) setDialog(() => end = t);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: venueCtrl,
                  decoration:
                      InputDecoration(hintText: lang.flavor == 'english' ? 'Venue (optional)' : 'Mahali (hiari)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(lang.flavor == 'english' ? 'Cancel' : 'Ghairi')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: TCC.accent, foregroundColor: Colors.black),
              onPressed: () async {
                final unit = unitCtrl.text.trim();
                if (unit.isEmpty) return;
                final db = ref.read(dbProvider);
                await db.into(db.timetableClasses).insert(
                      TimetableClassesCompanion.insert(
                        unit: unit,
                        weekday: weekday,
                        startTime: fmt(start),
                        endTime: fmt(end),
                        venue: Value(venueCtrl.text.trim().isEmpty
                             ? null
                             : venueCtrl.text.trim()),
                      ),
                    );
                if (c.mounted) {
                  Navigator.pop(c);
                  poa(context, lang.flavor == 'english' ? 'Class added successfully!' : 'Poa! Darasa limeongezwa');
                }
              },
              child: Text(lang.flavor == 'english' ? 'Add' : 'Weka'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField(
      BuildContext context, String label, String value, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(TCC.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: TCC.surface2,
          borderRadius: BorderRadius.circular(TCC.radiusSm),
          border: Border.all(color: TCC.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: TCC.textMuted, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: TCC.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
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
