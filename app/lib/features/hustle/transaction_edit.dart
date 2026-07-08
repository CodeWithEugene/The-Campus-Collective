import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P20 — add / edit a single transaction / P21 — Receipt Scan Confirm.
class TransactionEdit extends ConsumerStatefulWidget {
  final String? id;
  final String? scanId;
  const TransactionEdit({super.key, this.id, this.scanId});
  @override
  ConsumerState<TransactionEdit> createState() => _TransactionEditState();
}

class _TransactionEditState extends ConsumerState<TransactionEdit> {
  static const _expenseCats = [
    'Food',
    'Rent',
    'Transport',
    'Data/Airtime',
    'Fun',
    'Shopping',
    'Health',
    'Other',
  ];
  static const _incomeCats = [
    'Allowance',
    'HELB',
    'Side hustle',
    'Gift',
    'Other',
  ];

  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();

  bool _isExpense = true;
  String? _category;
  DateTime _date = DateTime.now();
  bool _loading = false;
  bool get _editing => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_editing || widget.scanId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = ref.read(dbProvider);
    final id = int.tryParse(widget.id ?? '');
    final scanId = int.tryParse(widget.scanId ?? '');

    if (id != null) {
      final row = await (db.select(db.transactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null && mounted) {
        _amount.text = row.amount.abs().round().toString();
        _title.text = row.title;
        _note.text = row.note ?? '';
        _isExpense = row.amount < 0;
        _category = row.category;
        _date = row.date;
      }
    } else if (scanId != null) {
      final scanRow = await (db.select(db.scans)
            ..where((t) => t.id.equals(scanId)))
          .getSingleOrNull();
      if (scanRow != null && mounted) {
        try {
          final data = jsonDecode(scanRow.resultJson) as Map<String, dynamic>;
          final amountVal = data['amount'] ?? data['total'];
          if (amountVal != null) {
            _amount.text = amountVal.toString().split('.').first;
          }
          final merchantVal = data['merchant'] ?? data['merchantName'] ?? data['title'];
          if (merchantVal != null) {
            _title.text = merchantVal.toString();
          }
          final catVal = data['category'];
          if (catVal != null) {
            final categoryStr = catVal.toString();
            final normalized = categoryStr.isEmpty
                ? 'Other'
                : categoryStr[0].toUpperCase() + categoryStr.substring(1).toLowerCase();
            if (_expenseCats.contains(normalized) || _incomeCats.contains(normalized)) {
              _category = normalized;
            } else {
              _category = 'Other';
            }
          }
          final dateVal = data['date'];
          if (dateVal != null) {
            final parsedDate = DateTime.tryParse(dateVal.toString());
            if (parsedDate != null) {
              _date = parsedDate;
            }
          }
          _note.text = 'Parsed from receipt scan';
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lang = ref.read(langProvider);
    final amt = double.tryParse(_amount.text.trim()) ?? 0;
    if (amt <= 0) {
      _snack(lang.flavor == 'english'
          ? 'Please enter an amount greater than 0.'
          : (lang.flavor == 'sheng' ? 'Weka amount kubwa kuliko 0.' : 'Tafadhali weka kiasi kikubwa kuliko 0.'));
      return;
    }
    if (_category == null) {
      _snack(lang.flavor == 'english'
          ? 'Please select a category.'
          : (lang.flavor == 'sheng' ? 'Chagua category.' : 'Tafadhali chagua kategoria.'));
      return;
    }
    final signed = _isExpense ? -amt : amt;
    final title = _title.text.trim().isEmpty ? _category! : _title.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final db = ref.read(dbProvider);
    final id = int.tryParse(widget.id ?? '');

    if (_editing && id != null) {
      await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          title: Value(title),
          amount: Value(signed),
          category: Value(_category!),
          date: Value(_date),
          note: Value(note),
        ),
      );
    } else {
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              title: title,
              amount: signed,
              date: _date,
              category: Value(_category!),
              note: Value(note),
            ),
          );
    }
    if (!mounted) return;
    poa(context, lang.flavor == 'english' ? 'Saved successfully!' : 'Imehifadhiwa!');
    context.pop();
  }

  Future<void> _delete() async {
    final lang = ref.read(langProvider);
    final id = int.tryParse(widget.id ?? '');
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface,
        title: Text(lang.flavor == 'english' ? 'Delete transaction?' : 'Futa giaocha?'),
        content: Text(lang.flavor == 'english'
            ? 'This action cannot be undone.'
            : (lang.flavor == 'sheng' ? 'Hii haiwezi kurudishwa.' : 'Kitendo hiki hakiwezi kubatilishwa.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(lang.flavor == 'english' ? 'Cancel' : 'Ghairi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TCC.danger),
            onPressed: () => Navigator.pop(c, true),
            child: Text(lang.flavor == 'english' ? 'Delete' : 'Futa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(dbProvider);
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
    if (!mounted) return;
    poa(context, lang.flavor == 'english' ? 'Deleted.' : 'Imefutwa.');
    context.pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    if (_loading) {
      return TccScaffold(
        title: _editing ? (lang.flavor == 'english' ? 'Edit' : 'Hariri') : (lang.flavor == 'english' ? 'Add expense' : 'Weka gharama'),
        body: const Center(child: CircularProgressIndicator(color: TCC.accent)),
      );
    }
    final cats = _isExpense ? _expenseCats : _incomeCats;
    if (_category != null && !cats.contains(_category)) _category = null;

    return TccScaffold(
      title: _editing
          ? (lang.flavor == 'english' ? 'Edit transaction' : 'Hariri muamala')
          : (lang.flavor == 'english' ? 'Add transaction' : 'Weka muamala'),
      actions: [
        if (_editing)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: TCC.danger),
            onPressed: _delete,
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _amountField(lang),
          const SizedBox(height: 20),
          _typeToggle(lang),
          const SizedBox(height: 24),
          SectionHeader(lang.flavor == 'english' ? 'Category' : 'Kategoria'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cats
                .map((c) => TccChip(
                      label: lang.flavor == 'english'
                          ? c
                          : (c == 'Food'
                              ? 'Chakula'
                              : (c == 'Rent'
                                  ? 'Kodi'
                                  : (c == 'Transport'
                                      ? 'Usafiri'
                                      : (c == 'Data/Airtime'
                                          ? 'Bando'
                                          : (c == 'Fun'
                                              ? 'Burudani'
                                              : (c == 'Shopping'
                                                  ? 'Shopping'
                                                  : (c == 'Health'
                                                      ? 'Afya'
                                                      : (c == 'Allowance'
                                                          ? 'Mfuko'
                                                          : (c == 'HELB'
                                                              ? 'HELB'
                                                              : (c == 'Side hustle'
                                                                  ? 'Kazi ya kando'
                                                                  : (c == 'Gift'
                                                                      ? 'Zawadi'
                                                                      : 'Nyingine'))))))))))),
                      icon: _iconFor(c),
                      selected: _category == c,
                      tint: TCC.hustle,
                      onTap: () => setState(() => _category = c),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: TCC.text),
            decoration: InputDecoration(
              labelText: lang.flavor == 'english' ? 'Title (optional)' : 'Jina (hiari)',
              prefixIcon: const Icon(Icons.edit_note_rounded, color: TCC.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          _dateTile(lang),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: TCC.text),
            decoration: InputDecoration(
              labelText: lang.flavor == 'english' ? 'Note (optional)' : 'Maelezo (hiari)',
              prefixIcon: const Icon(Icons.sticky_note_2_outlined, color: TCC.textMuted),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: TCC.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(lang.flavor == 'english' ? 'Save' : 'Hifadhi'),
          ),
        ],
      ),
    );
  }

  Widget _amountField(LangPref lang) {
    final color = _isExpense ? TCC.danger : TCC.hustle;
    return Column(
      children: [
        Text(
          _isExpense
              ? (lang.flavor == 'english' ? 'Expense' : 'Gharama')
              : (lang.flavor == 'english' ? 'Income' : 'Kipato'),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 6, right: 4),
              child: Text('KSh',
                  style: TextStyle(color: TCC.textMuted, fontSize: 20)),
            ),
            IntrinsicWidth(
              child: TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    color: TCC.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 44,
                    letterSpacing: -1),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: TCC.textDisabled, fontSize: 44),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _typeToggle(LangPref lang) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TCC.surface2,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TCC.border),
      ),
      child: Row(
        children: [
          _toggleHalf(
            lang.flavor == 'english' ? 'Expense' : 'Gharama',
            _isExpense,
            TCC.danger,
            () => setState(() => _isExpense = true),
          ),
          _toggleHalf(
            lang.flavor == 'english' ? 'Income' : 'Kipato',
            !_isExpense,
            TCC.hustle,
            () => setState(() => _isExpense = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleHalf(String label, bool active, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: active ? color : Colors.transparent, width: 1),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? color : TCC.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    );
  }

  Widget _dateTile(LangPref lang) {
    final now = DateTime.now();
    final isToday = _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    return TccCard(
      onTap: _pickDate,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 20, color: TCC.textMuted),
          const SizedBox(width: 14),
          Text(lang.flavor == 'english' ? 'Date' : 'Tarehe', style: const TextStyle(color: TCC.text, fontSize: 15)),
          const Spacer(),
          Text(isToday ? (lang.flavor == 'english' ? 'Today' : 'Leo') : DateFormat('d MMM yyyy').format(_date),
              style: const TextStyle(
                  color: TCC.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: TCC.textMuted),
        ],
      ),
    );
  }
}

IconData _iconFor(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.restaurant_rounded;
    case 'rent':
      return Icons.home_rounded;
    case 'transport':
      return Icons.directions_bus_rounded;
    case 'data/airtime':
    case 'data':
    case 'airtime':
      return Icons.wifi_rounded;
    case 'fun':
      return Icons.celebration_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'allowance':
      return Icons.volunteer_activism_rounded;
    case 'helb':
      return Icons.school_rounded;
    case 'side hustle':
      return Icons.work_rounded;
    case 'gift':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.category_rounded;
  }
}
