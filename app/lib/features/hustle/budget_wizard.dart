import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P18 — 3-step budget wizard: income → fixed costs → AI-generated budget.
class BudgetWizard extends ConsumerStatefulWidget {
  const BudgetWizard({super.key});
  @override
  ConsumerState<BudgetWizard> createState() => _BudgetWizardState();
}

class _BudgetWizardState extends ConsumerState<BudgetWizard> {
  final _page = PageController();
  int _step = 0;

  // Step 1 — income
  final _helb = TextEditingController();
  final _allowance = TextEditingController();
  final _side = TextEditingController();
  final _otherIncome = TextEditingController();

  // Step 2 — fixed costs
  final _rent = TextEditingController();
  final _transport = TextEditingController();
  final _data = TextEditingController();

  // User-defined labeled rows (project ask: budgets differ per student —
  // e.g. bursary income, chama contribution, hostel wifi). Persisted locally.
  final List<_CustomField> _extraIncome = [];
  final List<_CustomField> _extraFixed = [];

  // Step 3 — generated categories
  bool _cooking = false;
  List<_CatDraft> _drafts = [];

  double get _monthlyIncome {
    double v(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
    return v(_helb) / 4 +
        v(_allowance) +
        v(_side) +
        v(_otherIncome) +
        _extraIncome.fold(0.0, (s, f) => s + f.value);
  }

  double get _fixedTotal {
    double v(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
    return v(_rent) +
        v(_transport) +
        v(_data) +
        _extraFixed.fold(0.0, (s, f) => s + f.value);
  }

  @override
  void initState() {
    super.initState();
    _restoreInputs();
  }

  /// Pre-fill from the last accepted budget so a re-run doesn't start blank.
  Future<void> _restoreInputs() async {
    final prefs = ref.read(prefsProvider).valueOrNull;
    final raw = prefs?.getString('budgetInputs');
    if (raw == null) return;
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _helb.text = saved['helb'] ?? '';
      _allowance.text = saved['allowance'] ?? '';
      _side.text = saved['side'] ?? '';
      _otherIncome.text = saved['other'] ?? '';
      _rent.text = saved['rent'] ?? '';
      _transport.text = saved['transport'] ?? '';
      _data.text = saved['data'] ?? '';
      for (final e in (saved['extraIncome'] as List? ?? const [])) {
        _extraIncome.add(_CustomField(e['name'] ?? '', e['amount'] ?? ''));
      }
      for (final e in (saved['extraFixed'] as List? ?? const [])) {
        _extraFixed.add(_CustomField(e['name'] ?? '', e['amount'] ?? ''));
      }
    });
  }

  Future<void> _saveInputs() async {
    final prefs = ref.read(prefsProvider).valueOrNull;
    if (prefs == null) return;
    await prefs.setString(
        'budgetInputs',
        jsonEncode({
          'helb': _helb.text,
          'allowance': _allowance.text,
          'side': _side.text,
          'other': _otherIncome.text,
          'rent': _rent.text,
          'transport': _transport.text,
          'data': _data.text,
          'extraIncome': [
            for (final f in _extraIncome)
              if (f.name.text.trim().isNotEmpty)
                {'name': f.name.text, 'amount': f.amount.text}
          ],
          'extraFixed': [
            for (final f in _extraFixed)
              if (f.name.text.trim().isNotEmpty)
                {'name': f.name.text, 'amount': f.amount.text}
          ],
        }));
  }

  @override
  void dispose() {
    _page.dispose();
    for (final c in [
      _helb,
      _allowance,
      _side,
      _otherIncome,
      _rent,
      _transport,
      _data
    ]) {
      c.dispose();
    }
    for (final f in [..._extraIncome, ..._extraFixed]) {
      f.dispose();
    }
    for (final d in _drafts) {
      d.controller.dispose();
    }
    super.dispose();
  }

  void _goto(int i) {
    setState(() => _step = i);
    _page.animateToPage(i,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  Future<void> _generate() async {
    setState(() => _cooking = true);
    final gemma = ref.read(gemmaProvider);
    final extraCosts = _extraFixed
        .where((f) => f.name.text.trim().isNotEmpty && f.value > 0)
        .map((f) => '${f.name.text.trim()} ${f.amount.text}')
        .join(', ');
    final prompt =
        'Monthly income KES ${_monthlyIncome.round()}. Fixed costs: rent '
        '${_rent.text}, transport ${_transport.text}, data ${_data.text}'
        '${extraCosts.isEmpty ? '' : ', $extraCosts'}. '
        'Make a realistic student budget.';
    final result = await gemma.structured(prompt, schemaHint: 'budget');
    final cats = (result['categories'] as List?) ?? const [];
    final drafts = <_CatDraft>[];
    for (final c in cats) {
      final name = (c['name'] ?? 'Other').toString();
      final limit = ((c['limit'] ?? 0) as num).toDouble();
      drafts.add(_CatDraft(name, limit));
    }
    if (!mounted) return;
    if (drafts.isEmpty) {
      // Model hiccup (structured() returns {} on failure): stay on step 2
      // instead of landing the user on an empty, un-acceptable step 3.
      setState(() => _cooking = false);
      final lang = ref.read(langProvider);
      poa(
          context,
          lang.flavor == 'english'
              ? 'The AI could not build a budget — try again.'
              : 'AI haikuweza kutengeneza bajeti — jaribu tena.');
      return;
    }
    setState(() {
      _drafts = drafts;
      _cooking = false;
    });
    _goto(2);
  }

  double get _draftTotal =>
      _drafts.fold(0.0, (s, d) => s + (double.tryParse(d.controller.text) ?? 0));

  Future<void> _accept() async {
    final lang = ref.read(langProvider);
    final db = ref.read(dbProvider);
    await _saveInputs();
    await db.delete(db.budgetCategories).go();
    for (final d in _drafts) {
      final limit = double.tryParse(d.controller.text) ?? 0;
      if (limit <= 0) continue;
      await db.into(db.budgetCategories).insert(
            BudgetCategoriesCompanion.insert(name: d.name, limit: limit),
          );
    }
    if (!mounted) return;
    poa(context,
        lang.flavor == 'english' ? 'Budget saved!' : 'Bajeti imewekwa!');
    context.go('/hustle');
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: lang.flavor == 'english' ? 'Make a budget' : 'Tengeneza bajeti',
      body: _cooking
          ? _cookingView(lang)
          : Column(
              children: [
                _stepIndicator(),
                Expanded(
                  child: PageView(
                    controller: _page,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _step = i),
                    children: [_step1(lang), _step2(lang), _step3(lang)],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _cookingView(LangPref lang) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: TCC.accent),
            const SizedBox(height: 20),
            Text(
              lang.flavor == 'english' ? 'Cooking your budget…' : 'Tengeneza bajeti…',
              style: const TextStyle(color: TCC.text, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              lang.flavor == 'english'
                  ? 'Structuring your money intelligently.'
                  : (lang.flavor == 'sheng' ? 'Napanga pesa zako kwa akili.' : 'Napanga pesa zako kwa akili.'),
              style: const TextStyle(color: TCC.textMuted, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              height: 5,
              decoration: BoxDecoration(
                color: active ? TCC.hustle : TCC.surface2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---- Step 1: income ----
  Widget _step1(LangPref lang) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _stepHeader(
          'Step 1',
          lang.flavor == 'english' ? 'Monthly Income' : (lang.flavor == 'sheng' ? 'Pesa zinaingia' : 'Mapato ya Kila Mwezi'),
          lang.flavor == 'english' ? 'How much comes in each month?' : 'Unapata kiasi gani kila mwezi?',
        ),
        _moneyField(_helb, lang.flavor == 'english' ? 'HELB (per semester)' : 'HELB (kwa muhula)',
            icon: Icons.school_rounded,
            hint: double.tryParse(_helb.text) != null && double.parse(_helb.text) > 0
                ? '≈ ${_kes(double.parse(_helb.text) / 4)} / ${lang.flavor == 'english' ? 'month' : 'mwezi'}'
                : (lang.flavor == 'english' ? 'Split into ~4 months' : 'Gawanya kwa miezi 4')),
        _moneyField(_allowance, lang.flavor == 'english' ? 'Allowance' : 'Pesa za mfukoni', icon: Icons.volunteer_activism_rounded),
        _moneyField(_side, lang.flavor == 'english' ? 'Side hustle' : 'Kazi za kando', icon: Icons.work_rounded),
        _moneyField(_otherIncome, lang.flavor == 'english' ? 'Other' : 'Zinginezo', icon: Icons.add_circle_outline_rounded),
        ..._extraIncome.map((f) => _customFieldRow(f, _extraIncome, lang)),
        _addFieldButton(
          lang.flavor == 'english' ? 'Add income source' : 'Ongeza chanzo cha mapato',
          () => setState(() => _extraIncome.add(_CustomField())),
        ),
        const SizedBox(height: 12),
        _runningTotal(lang.flavor == 'english' ? 'Monthly income' : 'Jumla ya mapato', _monthlyIncome, TCC.hustle),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => _goto(1),
          style: _primaryBtn(),
          child: Text(lang.flavor == 'english' ? 'Next' : 'Mbele'),
        ),
      ],
    );
  }

  // ---- Step 2: fixed costs ----
  Widget _step2(LangPref lang) {
    final fixed = _fixedTotal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _stepHeader(
          'Step 2',
          lang.flavor == 'english' ? 'Fixed Costs' : (lang.flavor == 'sheng' ? 'Gharama za lazima' : 'Gharama Zisizobadilika'),
          lang.flavor == 'english' ? 'Costs you pay every month.' : 'Gharama unazolipa kila mwezi.',
        ),
        _moneyField(_rent, lang.flavor == 'english' ? 'Rent' : 'Kodi', icon: Icons.home_rounded),
        _moneyField(_transport, lang.flavor == 'english' ? 'Transport' : 'Usafiri', icon: Icons.directions_bus_rounded),
        _moneyField(_data, lang.flavor == 'english' ? 'Data' : 'Bando', icon: Icons.wifi_rounded),
        ..._extraFixed.map((f) => _customFieldRow(f, _extraFixed, lang)),
        _addFieldButton(
          lang.flavor == 'english' ? 'Add fixed cost' : 'Ongeza gharama nyingine',
          () => setState(() => _extraFixed.add(_CustomField())),
        ),
        const SizedBox(height: 12),
        _runningTotal(lang.flavor == 'english' ? 'Fixed costs' : 'Jumla ya gharama', fixed, TCC.warning),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goto(0),
                style: _ghostBtn(),
                child: Text(lang.flavor == 'english' ? 'Back' : 'Nyuma'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _generate,
                style: _primaryBtn(),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(lang.flavor == 'english' ? 'Generate budget' : 'Tengeneza bajeti'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Step 3: editable generated budget ----
  Widget _step3(LangPref lang) {
    final total = _draftTotal;
    final income = _monthlyIncome;
    final over = income > 0 && total > income;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _stepHeader(
          'Step 3',
          lang.flavor == 'english' ? 'Your Budget' : (lang.flavor == 'sheng' ? 'Budget yako' : 'Bajeti Yako'),
          lang.flavor == 'english' ? 'Tweak any limit, then accept.' : 'Rekebisha kikomo chochote, kisha ukubali.',
        ),
        if (over)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TCC.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.danger.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: TCC.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang.flavor == 'english'
                        ? 'Your budget is ${_kes(total)} but your income is ${_kes(income)}. You are ${_kes(total - income)} over — please reduce some limits.'
                        : (lang.flavor == 'sheng'
                            ? 'Budget ni ${_kes(total)} lakini income ni ${_kes(income)}. Uko ${_kes(total - income)} juu — punguza kidogo.'
                            : 'Bajeti ni ${_kes(total)} lakini mapato ni ${_kes(income)}. Umezidi kwa ${_kes(total - income)} — tafadhali punguza vikomo.'),
                    style: const TextStyle(color: TCC.text, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ..._drafts.map(_draftRow),
        _addFieldButton(
          lang.flavor == 'english' ? 'Add category' : 'Ongeza kategoria',
          () => _addCategoryDialog(lang),
        ),
        const SizedBox(height: 8),
        _runningTotal(lang.flavor == 'english' ? 'Total budget' : 'Jumla ya bajeti', total, over ? TCC.danger : TCC.hustle),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goto(1),
                style: _ghostBtn(),
                child: Text(lang.flavor == 'english' ? 'Back' : 'Nyuma'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _drafts.isEmpty ? null : _accept,
                style: _primaryBtn(),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(lang.flavor == 'english' ? 'Accept budget' : 'Kubali bajeti'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addCategoryDialog(LangPref lang) async {
    final name = TextEditingController();
    final limit = TextEditingController();
    final en = lang.flavor == 'english';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface2,
        title: Text(en ? 'New category' : 'Kategoria mpya',
            style: const TextStyle(color: TCC.text, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: TCC.text),
              decoration:
                  InputDecoration(labelText: en ? 'Name' : 'Jina'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limit,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: TCC.text),
              decoration: InputDecoration(
                  labelText: en ? 'Monthly limit' : 'Kikomo cha mwezi',
                  prefixText: 'KSh '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(en ? 'Cancel' : 'Ghairi')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(en ? 'Add' : 'Ongeza')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(() => _drafts = [
            ..._drafts,
            _CatDraft(name.text.trim(), double.tryParse(limit.text) ?? 0),
          ]);
    }
    name.dispose();
    limit.dispose();
  }

  Widget _draftRow(_CatDraft d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TccCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(_iconFor(d.name), size: 20, color: TCC.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(d.name,
                  style: const TextStyle(
                      color: TCC.text, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: d.controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.right,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    color: TCC.text, fontWeight: FontWeight.w700, fontSize: 15),
                decoration: const InputDecoration(
                  prefixText: 'KSh ',
                  prefixStyle: TextStyle(color: TCC.textMuted, fontSize: 13),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh_rounded, size: 18, color: TCC.textMuted),
              onPressed: () => setState(() => d.reset()),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close_rounded, size: 18, color: TCC.textMuted),
              onPressed: () => setState(() {
                _drafts = [..._drafts]..remove(d);
                d.controller.dispose();
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Reusable bits ----
  Widget _stepHeader(String kicker, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker.toUpperCase(),
              style: const TextStyle(
                  color: TCC.hustle,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _moneyField(TextEditingController c, String label,
      {required IconData icon, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: TCC.text, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperStyle: const TextStyle(color: TCC.hustle, fontSize: 12),
          prefixIcon: Icon(icon, color: TCC.textMuted, size: 20),
          prefixText: 'KSh ',
          prefixStyle: const TextStyle(color: TCC.textMuted),
        ),
      ),
    );
  }

  Widget _customFieldRow(
      _CustomField f, List<_CustomField> owner, LangPref lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: f.name,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: TCC.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: lang.flavor == 'english' ? 'Name' : 'Jina',
                prefixIcon: const Icon(Icons.edit_rounded,
                    color: TCC.textMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextField(
              controller: f.amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: TCC.text, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(prefixText: 'KSh '),
            ),
          ),
          IconButton(
            tooltip: lang.flavor == 'english' ? 'Remove' : 'Ondoa',
            icon: const Icon(Icons.close_rounded, size: 18, color: TCC.textMuted),
            onPressed: () => setState(() {
              owner.remove(f);
              f.dispose();
            }),
          ),
        ],
      ),
    );
  }

  Widget _addFieldButton(String label, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18, color: TCC.hustle),
        label: Text(label,
            style: const TextStyle(
                color: TCC.hustle, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _runningTotal(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TCC.radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: TCC.textMuted, fontSize: 14)),
          Text(_kes(value),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        ],
      ),
    );
  }

  ButtonStyle _primaryBtn() => FilledButton.styleFrom(
        backgroundColor: TCC.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
      );

  ButtonStyle _ghostBtn() => OutlinedButton.styleFrom(
        foregroundColor: TCC.text,
        side: const BorderSide(color: TCC.border),
        padding: const EdgeInsets.symmetric(vertical: 16),
      );
}

class _CatDraft {
  final String name;
  final double original;
  final TextEditingController controller;
  _CatDraft(this.name, this.original)
      : controller = TextEditingController(text: original.round().toString());
  void reset() => controller.text = original.round().toString();
}

/// A user-added, user-labeled money row (custom income source / fixed cost).
class _CustomField {
  final TextEditingController name;
  final TextEditingController amount;
  _CustomField([String label = '', String value = ''])
      : name = TextEditingController(text: label),
        amount = TextEditingController(text: value);
  double get value => double.tryParse(amount.text.trim()) ?? 0;
  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

String _kes(num v) => 'KSh ${NumberFormat.decimalPattern().format(v.round())}';

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
    default:
      return Icons.category_rounded;
  }
}
