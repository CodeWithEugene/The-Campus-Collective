import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P27 — create / edit a single task.
class TaskEditScreen extends ConsumerStatefulWidget {
  final String? id;
  const TaskEditScreen({super.key, this.id});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _due;
  int _priority = 1;
  bool _reminder = false;
  String _leadTime = '1 hr before';
  bool _loading = true;

  static const _leadOptions = [
    '15 min before',
    '1 hr before',
    'morning of',
    'day before',
  ];

  int? get _taskId => widget.id == null ? null : int.tryParse(widget.id!);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _taskId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final db = ref.read(dbProvider);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (task != null) {
      _title.text = task.title;
      _notes.text = task.notes ?? '';
      _due = task.dueAt;
      _priority = task.priority;
      _reminder = task.reminder;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due ?? now),
    );
    setState(() {
      _due = DateTime(date.year, date.month, date.day, time?.hour ?? 9,
          time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    final lang = ref.read(langProvider);
    final title = _title.text.trim();
    if (title.isEmpty) {
      poa(context, lang.flavor == 'english' ? 'Please enter a title' : 'Andika title kwanza');
      return;
    }
    final db = ref.read(dbProvider);
    // TODO: schedule a local notification here once notifications are wired;
    // for now the reminder flag + lead time are only persisted.
    final id = _taskId;
    if (id == null) {
      await db.into(db.tasks).insert(TasksCompanion.insert(
            title: title,
            dueAt: Value(_due),
            priority: Value(_priority),
            notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
            reminder: Value(_reminder),
          ));
    } else {
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: Value(title),
          dueAt: Value(_due),
          priority: Value(_priority),
          notes:
              Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
          reminder: Value(_reminder),
        ),
      );
    }
    if (mounted) {
      poa(context, lang.flavor == 'english' ? 'Saved successfully!' : 'Poa! Imehifadhiwa');
      context.pop();
    }
  }

  Future<void> _delete() async {
    final lang = ref.read(langProvider);
    final id = _taskId;
    if (id == null) {
      context.pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface,
        title: Text(lang.flavor == 'english' ? 'Delete task?' : 'Futa kazi?'),
        content: Text(lang.flavor == 'english' ? 'This can\'t be undone.' : 'Hili haliwezi kubatilishwa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(lang.flavor == 'english' ? 'Cancel' : 'Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(lang.flavor == 'english' ? 'Delete' : 'Futa', style: const TextStyle(color: TCC.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(dbProvider);
    await (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
    if (mounted) {
      poa(context, lang.flavor == 'english' ? 'Task deleted' : 'Kazi imefutwa');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: _taskId == null
          ? (lang.flavor == 'english' ? 'New task' : 'Kazi mpya')
          : (lang.flavor == 'english' ? 'Edit task' : 'Hariri kazi'),
      actions: [
        if (_taskId != null)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: TCC.danger),
            onPressed: _delete,
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TCC.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _label(lang.flavor == 'english' ? 'Title' : 'Kichwa'),
                TextField(
                  controller: _title,
                  autofocus: _taskId == null,
                  decoration: InputDecoration(
                    hintText: lang.flavor == 'english' ? 'e.g. HELB form' : 'mf. Fomu ya HELB',
                  ),
                ),
                const SizedBox(height: 22),
                _label(lang.flavor == 'english' ? 'Due' : 'Muda wa mwisho'),
                _dueField(lang),
                const SizedBox(height: 22),
                _label(lang.flavor == 'english' ? 'Priority' : 'Umuhimu'),
                _prioritySegmented(lang),
                const SizedBox(height: 22),
                _label(lang.flavor == 'english' ? 'Notes' : 'Maelezo'),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: lang.flavor == 'english' ? 'Any details…' : 'Maelezo yoyote…',
                  ),
                ),
                const SizedBox(height: 22),
                _reminderCard(lang),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: TCC.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _save,
                    child: Text(
                      lang.flavor == 'english' ? 'Save' : 'Hifadhi',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                if (_taskId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TCC.danger,
                        side: BorderSide(
                            color: TCC.danger.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _delete,
                      child: Text(lang.flavor == 'english' ? 'Delete' : 'Futa'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: TCC.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _dueField(LangPref lang) {
    return TccCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: _pickDue,
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 18, color: TCC.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _due == null
                  ? (lang.flavor == 'english' ? 'Set date & time' : 'Weka tarehe na muda')
                  : DateFormat('EEE, d MMM · HH:mm').format(_due!),
              style: TextStyle(
                  color: _due == null ? TCC.textMuted : TCC.text,
                  fontSize: 14.5),
            ),
          ),
          if (_due != null)
            GestureDetector(
              onTap: () => setState(() => _due = null),
              child: const Icon(Icons.close_rounded,
                  size: 18, color: TCC.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _prioritySegmented(LangPref lang) {
    final labels = lang.flavor == 'english' ? ['Low', 'Med', 'High'] : ['Chini', 'Kati', 'Juu'];
    const colors = [TCC.textMuted, TCC.warning, TCC.danger];
    return Container(
      decoration: BoxDecoration(
        color: TCC.surface2,
        borderRadius: BorderRadius.circular(TCC.radiusSm),
        border: Border.all(color: TCC.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _priority == i
                        ? colors[i].withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(TCC.radiusSm - 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: colors[i], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(labels[i],
                          style: TextStyle(
                            color: _priority == i ? colors[i] : TCC.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reminderCard(LangPref lang) {
    return TccCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: TCC.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang.flavor == 'english' ? 'Reminder' : 'Kikumbusho',
                  style: const TextStyle(
                      color: TCC.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _reminder,
                activeThumbColor: TCC.accent,
                onChanged: (v) => setState(() => _reminder = v),
              ),
            ],
          ),
          if (_reminder) ...[
            const Divider(color: TCC.border, height: 24),
            Row(
              children: [
                Text(
                  lang.flavor == 'english' ? 'Notify me' : 'Nikumbushe',
                  style: const TextStyle(color: TCC.textMuted, fontSize: 13),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _leadTime,
                  dropdownColor: TCC.surface2,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                      color: TCC.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600),
                  items: [
                    for (final o in _leadOptions)
                      DropdownMenuItem(
                        value: o,
                        child: Text(
                          lang.flavor == 'english'
                              ? o
                              : (o == '15 min before'
                                  ? 'Dakika 15 kabla'
                                  : (o == '1 hr before'
                                      ? 'Saa 1 kabla'
                                      : (o == 'morning of'
                                          ? 'Asubuhi hiyo'
                                          : 'Siku moja kabla'))),
                        ),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _leadTime = v ?? _leadTime),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
