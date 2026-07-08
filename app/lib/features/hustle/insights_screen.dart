import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// Selected month as an offset from the current month (0 = this month).
final _monthOffsetProvider = StateProvider.autoDispose<int>((_) => 0);

/// P22 — spending insights: donut breakdown, month deltas, AI notes, merchants.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: lang.flavor == 'english' ? 'Insights' : 'Ufahamu',
      body: StreamBuilder<List<Transaction>>(
        stream: db.select(db.transactions).watch(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: TCC.accent));
          }
          final all = snap.data!;
          if (!_hasWeekOfData(all)) {
            return EmptyState(
              icon: Icons.insights_rounded,
              title: lang.flavor == 'english' ? 'Not enough data yet' : 'Data haitoshi bado',
              subtitle: lang.flavor == 'english'
                  ? 'Record expenses for at least a week to see your spending patterns.'
                  : (lang.flavor == 'sheng'
                      ? 'Rekodi matumizi kwa angalau wiki moja ndio nikuonyeshe mwelekeo wa pesa zako.'
                      : 'Rekodi matumizi kwa angalau wiki moja ili nikuonyeshe mwelekeo wa pesa zako.'),
            );
          }
          return _InsightsBody(all: all);
        },
      ),
    );
  }

  bool _hasWeekOfData(List<Transaction> all) {
    final expenses = all.where((t) => t.amount < 0).toList();
    if (expenses.length < 3) return false;
    expenses.sort((a, b) => a.date.compareTo(b.date));
    final span = expenses.last.date.difference(expenses.first.date).inDays;
    return span >= 7;
  }
}

class _InsightsBody extends ConsumerWidget {
  final List<Transaction> all;
  const _InsightsBody({required this.all});

  static const _palette = [
    TCC.hustle,
    TCC.accent,
    TCC.primary,
    TCC.warning,
    Color(0xFF3DA5FF),
    Color(0xFFFF6FB5),
    Color(0xFF9B8CFF),
  ];

  DateTime _monthOf(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - offset, 1);
  }

  bool _inMonth(DateTime d, DateTime month) =>
      d.year == month.year && d.month == month.month;

  Map<String, double> _byCategory(DateTime month) {
    final map = <String, double>{};
    for (final t in all) {
      if (t.amount < 0 && _inMonth(t.date, month)) {
        map.update(t.category, (v) => v + -t.amount, ifAbsent: () => -t.amount);
      }
    }
    return map;
  }

  double _spendIn(DateTime month) => all
      .where((t) => t.amount < 0 && _inMonth(t.date, month))
      .fold(0.0, (s, t) => s + -t.amount);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(_monthOffsetProvider);
    final month = _monthOf(offset);
    final prevMonth = _monthOf(offset + 1);

    final byCat = _byCategory(month);
    final total = byCat.values.fold(0.0, (s, v) => s + v);
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final thisSpend = _spendIn(month);
    final lastSpend = _spendIn(prevMonth);

    final lang = ref.watch(langProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _monthSwitcher(context, ref, month, offset),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          _noSpendCard(month, lang)
        else ...[
          _donutCard(entries, total, lang),
          const SizedBox(height: 20),
          _deltaChips(thisSpend, lastSpend, lang),
          const SizedBox(height: 20),
          SectionHeader(lang.flavor == 'english' ? 'What I noticed' : 'Kile nilichoona'),
          ..._aiInsights(entries, total, thisSpend, lastSpend, lang),
          const SizedBox(height: 12),
          SectionHeader(lang.flavor == 'english' ? 'Top merchants' : 'Wauzaji wakuu'),
          _topMerchants(month),
        ],
      ],
    );
  }

  Widget _monthSwitcher(
      BuildContext context, WidgetRef ref, DateTime month, int offset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: TCC.text),
          onPressed: () =>
              ref.read(_monthOffsetProvider.notifier).state = offset + 1,
        ),
        Text(DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(
                color: TCC.text, fontSize: 17, fontWeight: FontWeight.w700)),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded,
              color: offset == 0 ? TCC.textDisabled : TCC.text),
          onPressed: offset == 0
              ? null
              : () =>
                  ref.read(_monthOffsetProvider.notifier).state = offset - 1,
        ),
      ],
    );
  }

  Widget _noSpendCard(DateTime month, LangPref lang) => TccCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              lang.flavor == 'english'
                  ? 'No expenses in ${DateFormat('MMMM').format(month)}.'
                  : (lang.flavor == 'sheng'
                      ? 'Hakuna matumizi ${DateFormat('MMMM').format(month)}.'
                      : 'Hakuna matumizi ${DateFormat('MMMM').format(month)}.'),
              style: const TextStyle(color: TCC.textMuted),
            ),
          ),
        ),
      );

  Widget _donutCard(
      List<MapEntry<String, double>> entries, double total, LangPref lang) {
    final slices = <_Slice>[];
    for (var i = 0; i < entries.length; i++) {
      slices.add(_Slice(entries[i].value, _palette[i % _palette.length]));
    }
    return TccCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _DonutPainter(slices, total),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_kes(total),
                        style: const TextStyle(
                            color: TCC.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 17)),
                    Text(lang.flavor == 'english' ? 'spent' : 'imetumika',
                        style:
                            const TextStyle(color: TCC.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < entries.length && i < 6; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _palette[i % _palette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(entries[i].key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: TCC.text, fontSize: 13)),
                        ),
                        Text(
                          '${((entries[i].value / total) * 100).round()}%',
                          style: const TextStyle(
                              color: TCC.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deltaChips(double thisSpend, double lastSpend, LangPref lang) {
    final diff = thisSpend - lastSpend;
    final up = diff > 0;
    final pct = lastSpend <= 0 ? null : (diff / lastSpend * 100).abs().round();
    return Row(
      children: [
        Expanded(
          child: _statChip(
              lang.flavor == 'english' ? 'This month' : 'Mwezi huu',
              _kes(thisSpend),
              TCC.text,
              null,
              null),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statChip(
            lang.flavor == 'english' ? 'vs last month' : 'vs mwezi jana',
            pct == null ? '—' : '$pct%',
            up ? TCC.danger : TCC.hustle,
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            up ? TCC.danger : TCC.hustle,
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color valueColor,
      IconData? icon, Color? iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: TCC.surface,
        borderRadius: BorderRadius.circular(TCC.radius),
        border: Border.all(color: TCC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: TCC.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _aiInsights(List<MapEntry<String, double>> entries, double total,
      double thisSpend, double lastSpend, LangPref lang) {
    final notes = <String>[];
    if (entries.isNotEmpty) {
      final top = entries.first;
      final share = ((top.value / total) * 100).round();
      notes.add(lang.flavor == 'english'
          ? '$share% of your spending went to ${top.key}. This is your largest category this month.'
          : (lang.flavor == 'sheng'
              ? '$share% ya matumizi yako ilienda kwa ${top.key}. Ndio kubwa zaidi mwezi huu.'
              : '$share% ya matumizi yako yalienda kwa ${top.key}. Ndiyo kategoria kubwa zaidi mwezi huu.'));
    }
    if (lastSpend > 0) {
      final diff = thisSpend - lastSpend;
      if (diff > 0) {
        notes.add(lang.flavor == 'english'
            ? 'You spent ${_kes(diff)} more than last month. Check where you can cut back.'
            : (lang.flavor == 'sheng'
                ? 'Umetumia ${_kes(diff)} zaidi ya mwezi jana. Angalia wapi unaweza kupunguza.'
                : 'Umetumia ${_kes(diff)} zaidi ya mwezi uliopita. Angalia wapi unaweza kupunguza.'));
      } else if (diff < 0) {
        notes.add(lang.flavor == 'english'
            ? 'Success! You saved ${_kes(diff.abs())} compared to last month. Keep it up!'
            : (lang.flavor == 'sheng'
                ? 'Poa! Umeokoa ${_kes(diff.abs())} ikilinganishwa na mwezi jana. Endelea hivyo.'
                : 'Vyema! Umeokoa ${_kes(diff.abs())} ikilinganishwa na mwezi uliopita. Endelea hivyo.'));
      }
    }
    if (entries.length >= 2) {
      notes.add(lang.flavor == 'english'
          ? 'Your top three categories (${entries.take(3).map((e) => e.key).join(', ')}) consume most of your money.'
          : (lang.flavor == 'sheng'
              ? 'Vitu vitatu vya juu (${entries.take(3).map((e) => e.key).join(', ')}) ndio vinakula pesa yako zaidi.'
              : 'Kategoria tatu za juu (${entries.take(3).map((e) => e.key).join(', ')}) ndizo zinazotumia pesa zako zaidi.'));
    }
    if (notes.isEmpty) {
      notes.add(lang.flavor == 'english'
          ? 'Keep recording expenses to get better advice.'
          : (lang.flavor == 'sheng'
              ? 'Endelea kurekodi matumizi ili nikupe ushauri bora.'
              : 'Endelea kurekodi matumizi ili nikupe ushauri bora.'));
    }
    return notes.map((n) => _insightCard(n)).toList();
  }

  Widget _insightCard(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TccCard(
        borderColor: TCC.hustle.withValues(alpha: 0.4),
        color: TCC.hustle.withValues(alpha: 0.05),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 18, color: TCC.hustle),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: TCC.text, fontSize: 14, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topMerchants(DateTime month) {
    final map = <String, double>{};
    for (final t in all) {
      if (t.amount < 0 && _inMonth(t.date, month)) {
        map.update(t.title, (v) => v + -t.amount, ifAbsent: () => -t.amount);
      }
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = list.take(5).toList();
    return TccCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TCC.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: TCC.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(top[i].key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: TCC.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(_kes(top[i].value),
                      style: const TextStyle(
                          color: TCC.text, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Slice {
  final double value;
  final Color color;
  _Slice(this.value, this.color);
}

String _kes(num v) => 'KSh ${NumberFormat.decimalPattern().format(v.round())}';

/// Hand-painted donut chart from category slices.
class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  final double total;
  _DonutPainter(this.slices, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 6;
    const stroke = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) return;
    var start = -math.pi / 2;
    const gap = 0.04;
    for (final s in slices) {
      final sweep = (s.value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = s.color;
      final drawSweep = (sweep - gap).clamp(0.0, 2 * math.pi);
      canvas.drawArc(rect, start + gap / 2, drawSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices.length != slices.length || old.total != total;
}
