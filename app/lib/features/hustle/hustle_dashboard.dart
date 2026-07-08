import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P17 — Hustle (Pesa) dashboard. Bottom-nav tab: month overview, budget
/// ring, category bars, weekly insight, and quick actions. Pure-black fintech.
class HustleDashboard extends ConsumerWidget {
  const HustleDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final lang = ref.watch(langProvider);
    return TccScaffold(
      showBack: false,
      title: lang.flavor == 'english' ? 'Finance' : (lang.flavor == 'sheng' ? 'Pesa' : 'Fedha'),
      actions: [
        IconButton(
          tooltip: lang.flavor == 'english' ? 'Insights' : 'Ufahamu',
          icon: const Icon(Icons.insights_rounded, color: TCC.textMuted),
          onPressed: () => context.push('/hustle/insights'),
        ),
      ],
      body: StreamBuilder<List<BudgetCategory>>(
        stream: db.select(db.budgetCategories).watch(),
        builder: (context, budgetSnap) {
          if (!budgetSnap.hasData) return _loading();
          final budgets = budgetSnap.data!;
          if (budgets.isEmpty) return _noBudget(context, lang);
          return StreamBuilder<List<Transaction>>(
            stream: db.select(db.transactions).watch(),
            builder: (context, txnSnap) {
              final txns = txnSnap.data ?? const <Transaction>[];
              return _Overview(budgets: budgets, txns: txns, lang: lang);
            },
          );
        },
      ),
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator(color: TCC.accent));

  Widget _noBudget(BuildContext context, LangPref lang) => EmptyState(
        icon: Icons.savings_rounded,
        title: lang.flavor == 'english' ? "No budget yet — let's make one" : "Huna bajeti bado — hebu tuunde moja",
        subtitle: lang.flavor == 'english'
            ? 'Create a budget to track your spending and savings each month.'
            : (lang.flavor == 'sheng'
                ? 'Tengeneza budget yako ndio uweze kufuatilia pesa zako kila mwezi.'
                : 'Unda bajeti yako ili uweze kufuatilia matumizi yako kila mwezi.'),
        action: FilledButton(
          onPressed: () => context.push('/hustle/budget/new'),
          child: Text(lang.flavor == 'english' ? 'Start' : 'Anza'),
        ),
      );
}

class _Overview extends StatelessWidget {
  final List<BudgetCategory> budgets;
  final List<Transaction> txns;
  final LangPref lang;
  const _Overview({required this.budgets, required this.txns, required this.lang});

  bool _sameMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  double _spentOf(String cat) => txns
      .where((t) => t.amount < 0 && t.category == cat && _sameMonth(t.date))
      .fold(0.0, (s, t) => s + -t.amount);

  double _weeklySpentOf(String cat) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return txns
        .where((t) =>
            t.amount < 0 && t.category == cat && t.date.isAfter(since))
        .fold(0.0, (s, t) => s + -t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = budgets.fold(0.0, (s, b) => s + b.limit);
    final totalSpent = budgets.fold(0.0, (s, b) => s + _spentOf(b.name));
    final left = (totalBudget - totalSpent).clamp(-999999.0, 999999.0);
    final pct = totalBudget <= 0 ? 0.0 : (totalSpent / totalBudget).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _monthChip(context),
        const SizedBox(height: 16),
        _heroCard(context, left: left, budget: totalBudget, spent: totalSpent, pct: pct),
        const SizedBox(height: 20),
        _weeklyChart(context),
        const SizedBox(height: 20),
        SectionHeader(lang.flavor == 'english' ? 'Categories' : 'Kategoria'),
        ...budgets.map((b) => _categoryBar(b)),
        const SizedBox(height: 20),
        _weeklyInsight(context),
        const SizedBox(height: 20),
        _actions(context),
        const SizedBox(height: 24),
        _footerLinks(context),
      ],
    );
  }

  Widget _weeklyChart(BuildContext context) {
    final now = DateTime.now();
    final List<(String, double)> dailyExpenses = [];

    // Calculate last 7 days (including today)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      final spent = txns
          .where((t) =>
              t.amount < 0 &&
              t.date.isAfter(dateStart.subtract(const Duration(microseconds: 1))) &&
              t.date.isBefore(dateEnd))
          .fold(0.0, (sum, t) => sum + -t.amount);

      final label = DateFormat('E').format(date); // e.g. Mon
      dailyExpenses.add((label, spent));
    }

    // Find max value to normalize height
    double maxSpent = dailyExpenses.fold(0.0, (max, item) => item.$2 > max ? item.$2 : max);
    if (maxSpent <= 0) maxSpent = 1.0; // Avoid divide by zero

    final isEnglish = lang.flavor == 'english';

    return TccCard(
      borderColor: TCC.hustle.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'Weekly Spend Trend' : 'Mwelekeo wa Wiki',
            style: const TextStyle(color: TCC.text, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyExpenses.map((day) {
                final ratio = (day.$2 / maxSpent).clamp(0.0, 1.0);
                final height = ratio * 72;
                final isToday = day.$1 == DateFormat('E').format(now);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (day.$2 > 0)
                      Text(
                        '${day.$2.round()}',
                        style: TextStyle(
                          color: isToday ? TCC.accent : TCC.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: height.clamp(4.0, 72.0),
                      decoration: BoxDecoration(
                        color: isToday ? TCC.accent : TCC.hustle.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isToday ? glow(TCC.accent, blur: 8, opacity: 0.2) : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.$1,
                      style: TextStyle(
                        color: isToday ? TCC.accent : TCC.textMuted,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthChip(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(DateTime.now());
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: TCC.surface2,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: TCC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: TCC.hustle),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: TCC.text, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context,
      {required double left,
      required double budget,
      required double spent,
      required double pct}) {
    final over = left < 0;
    final ringColor = pct >= 1
        ? TCC.danger
        : pct >= 0.85
            ? TCC.warning
            : TCC.hustle;
    return TccCard(
      color: TCC.surface,
      borderColor: TCC.border,
      shadow: glow(TCC.hustle, opacity: 0.18, blur: 34),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: _RingPainter(pct: pct, color: ringColor),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(pct * 100).round()}%',
                        style: const TextStyle(
                            color: TCC.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
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
                Text(
                    lang.flavor == 'english'
                        ? (over ? 'Over budget' : 'Left this month')
                        : (over ? 'Umezidi bajeti' : 'Iliyobaki mwezi huu'),
                    style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_kes(left.abs()),
                    style: TextStyle(
                        color: over ? TCC.danger : TCC.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                    lang.flavor == 'english'
                        ? 'of ${_kes(budget)} budget'
                        : 'kati ya ${_kes(budget)}',
                    style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.trending_down_rounded,
                        size: 15, color: TCC.textMuted),
                    const SizedBox(width: 6),
                    Text(
                        lang.flavor == 'english'
                            ? 'Spent ${_kes(spent)}'
                            : 'Umetumia ${_kes(spent)}',
                        style:
                            const TextStyle(color: TCC.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(BudgetCategory b) {
    final spent = _spentOf(b.name);
    final limit = b.limit <= 0 ? 1.0 : b.limit;
    final ratio = (spent / limit).clamp(0.0, 1.0);
    final over = spent > b.limit;
    final barColor = over
        ? TCC.danger
        : ratio >= 0.85
            ? TCC.warning
            : TCC.hustle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(b.name), size: 18, color: TCC.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(b.name,
                    style: const TextStyle(
                        color: TCC.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              Text('${_kes(spent)} / ${_kes(b.limit)}',
                  style: TextStyle(
                      color: over ? TCC.danger : TCC.textMuted,
                      fontWeight: over ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: TCC.surface2),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(height: 6, color: barColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyInsight(BuildContext context) {
    // Find the category doing best (most under its weekly share) or worst.
    BudgetCategory? best;
    double bestUnder = -1e9;
    BudgetCategory? worst;
    double worstOver = -1e9;
    for (final b in budgets) {
      final weeklyLimit = b.limit / 4.345;
      final weeklySpent = _weeklySpentOf(b.name);
      final under = weeklyLimit - weeklySpent;
      if (under > bestUnder) {
        bestUnder = under;
        best = b;
      }
      final over = weeklySpent - weeklyLimit;
      if (over > worstOver) {
        worstOver = over;
        worst = b;
      }
    }

    final bool positive = bestUnder >= 0 || worst == null || worstOver <= 0;
    final Color border = positive ? TCC.accent : TCC.warning;
    final String emoji = positive ? '🟢' : '🟠';
    String text;
    if (positive && best != null) {
      text = lang.flavor == 'english'
          ? "Great — you're ${_kes(bestUnder.abs())} under on ${best.name} this week."
          : (lang.flavor == 'sheng'
              ? "Poa — you're ${_kes(bestUnder.abs())} under on ${best.name} this week."
              : "Vyema — uko chini kwa ${_kes(bestUnder.abs())} kwenye ${best.name} wiki hii.");
    } else if (worst != null) {
      text = lang.flavor == 'english'
          ? "Alert — you're ${_kes(worstOver.abs())} over on ${worst.name} this week."
          : (lang.flavor == 'sheng'
              ? "Angalia — uko ${_kes(worstOver.abs())} over on ${worst.name} this week."
              : "Angalia — umezidi kwa ${_kes(worstOver.abs())} kwenye ${worst.name} wiki hii.");
    } else {
      text = lang.flavor == 'english'
          ? 'Start logging expenses to get weekly insights.'
          : (lang.flavor == 'sheng'
              ? 'Anza kurekodi matumizi ili nikupe insight ya wiki.'
              : 'Anza kurekodi matumizi ili upate uchambuzi wa wiki.');
    }

    return TccCard(
      borderColor: border.withValues(alpha: 0.6),
      color: border.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/hustle/insights'),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.flavor == 'english' ? 'Weekly insight' : (lang.flavor == 'sheng' ? 'Insight ya wiki' : 'Uchambuzi wa wiki'),
                  style: const TextStyle(
                      color: TCC.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4),
                ),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        color: TCC.text, fontSize: 14, height: 1.35)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: TCC.textMuted),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push('/hustle/transactions/edit'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  lang.flavor == 'english' ? 'Add expense' : (lang.flavor == 'sheng' ? 'Add expense' : 'Weka matumizi'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: TCC.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/scan/camera?intent=expense'),
                icon: const Icon(Icons.document_scanner_rounded, size: 20),
                label: Text(
                  lang.flavor == 'english' ? 'Scan receipt' : (lang.flavor == 'sheng' ? 'Scan risiti' : 'Changanua risiti'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TCC.text,
                  side: const BorderSide(color: TCC.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/hustle/budget/new'),
            icon: const Icon(Icons.tune_rounded, size: 20),
            label: Text(
              lang.flavor == 'english' ? 'Make a budget' : (lang.flavor == 'sheng' ? 'Tengeneza budget' : 'Tengeneza bajeti'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: TCC.text,
              side: const BorderSide(color: TCC.border),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _footerLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => context.push('/hustle/transactions'),
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: Text(
            lang.flavor == 'english' ? 'View all transactions' : (lang.flavor == 'sheng' ? 'Transactions zote' : 'Giaocha zote'),
          ),
          style: TextButton.styleFrom(foregroundColor: TCC.textMuted),
        ),
        TextButton.icon(
          onPressed: () => context.push('/hustle/insights'),
          icon: const Icon(Icons.insights_rounded, size: 18),
          label: Text(
            lang.flavor == 'english' ? 'See insights' : 'Angalia ufahamu',
          ),
          style: TextButton.styleFrom(foregroundColor: TCC.hustle),
        ),
      ],
    );
  }
}

// ---- Shared helpers ----

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

/// Hand-painted circular budget progress ring.
class _RingPainter extends CustomPainter {
  final double pct;
  final Color color;
  _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 5;
    const stroke = 9.0;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = TCC.surface2;
    canvas.drawCircle(center, radius, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.5), color],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * pct.clamp(0.0, 1.0),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.pct != pct || old.color != color;
}
