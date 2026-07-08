import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// Filter state for the transactions list (All | Expense | Income).
final _txnFilterProvider = StateProvider.autoDispose<String>((_) => 'All');

/// P19 — full transaction ledger grouped by day.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final filter = ref.watch(_txnFilterProvider);
    final lang = ref.watch(langProvider);

    return TccScaffold(
      title: lang.flavor == 'english' ? 'Transactions' : (lang.flavor == 'sheng' ? 'Giaocha' : 'Miamala'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TCC.accent,
        foregroundColor: Colors.black,
        onPressed: () => context.push('/hustle/transactions/edit'),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                for (final f in ['All', 'Expense', 'Income']) ...[
                  TccChip(
                    label: f == 'All'
                        ? (lang.flavor == 'english' ? 'All' : 'Zote')
                        : (f == 'Expense'
                            ? (lang.flavor == 'english' ? 'Expense' : 'Matumizi')
                            : (lang.flavor == 'english' ? 'Income' : 'Mapato')),
                    selected: filter == f,
                    tint: TCC.hustle,
                    onTap: () =>
                        ref.read(_txnFilterProvider.notifier).state = f,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: db.select(db.transactions).watch(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: TCC.accent));
                }
                var rows = [...snap.data!]
                  ..sort((a, b) => b.date.compareTo(a.date));
                if (filter == 'Expense') {
                  rows = rows.where((t) => t.amount < 0).toList();
                } else if (filter == 'Income') {
                  rows = rows.where((t) => t.amount > 0).toList();
                }
                if (rows.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: lang.flavor == 'english'
                        ? (filter == 'All' ? 'No transactions yet' : 'No $filter transactions')
                        : (filter == 'All' ? 'Hakuna miamala bado' : 'Hakuna miamala ya $filter'),
                    subtitle: lang.flavor == 'english'
                        ? 'Add your first expense by clicking +.'
                        : (lang.flavor == 'sheng'
                            ? 'Weka expense yako ya kwanza kwa kubonyeza +.'
                            : 'Weka matumizi yako ya kwanza kwa kubonyeza +.'),
                    action: FilledButton(
                      onPressed: () =>
                          context.push('/hustle/transactions/edit'),
                      child: Text(lang.flavor == 'english' ? 'Add one' : 'Weka moja'),
                    ),
                  );
                }
                return _GroupedList(rows: rows, lang: lang);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<Transaction> rows;
  final LangPref lang;
  const _GroupedList({required this.rows, required this.lang});

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return lang.flavor == 'english' ? 'Today' : 'Leo';
    if (diff == 1) return lang.flavor == 'english' ? 'Yesterday' : 'Jana';
    return DateFormat('EEE, d MMM').format(d);
  }

  @override
  Widget build(BuildContext context) {
    // Group in order (rows are already date-desc).
    final groups = <String, List<Transaction>>{};
    for (final t in rows) {
      groups.putIfAbsent(_dayLabel(t.date), () => []).add(t);
    }
    final entries = groups.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final dayTotal = e.value.fold(0.0, (s, t) => s + t.amount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key,
                      style: const TextStyle(
                          color: TCC.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text('${dayTotal >= 0 ? '+' : '−'}${_kes(dayTotal.abs())}',
                      style: TextStyle(
                          color: dayTotal >= 0 ? TCC.hustle : TCC.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            ...e.value.map((t) => _row(context, t, lang)),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, Transaction t, LangPref lang) {
    final income = t.amount > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TccCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () =>
            context.push('/hustle/transactions/edit?id=${t.id}'),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (income ? TCC.hustle : TCC.textMuted)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                income ? Icons.south_west_rounded : _iconFor(t.category),
                size: 20,
                color: income ? TCC.hustle : TCC.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: TCC.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: TCC.surface2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lang.flavor == 'english'
                              ? t.category
                              : (t.category == 'Food'
                                  ? 'Chakula'
                                  : (t.category == 'Rent'
                                      ? 'Kodi'
                                      : (t.category == 'Transport'
                                          ? 'Usafiri'
                                          : (t.category == 'Data/Airtime'
                                              ? 'Bando'
                                              : (t.category == 'Fun'
                                                  ? 'Burudani'
                                                  : (t.category == 'Shopping'
                                                      ? 'Shopping'
                                                      : (t.category == 'Health'
                                                          ? 'Afya'
                                                          : (t.category == 'Allowance'
                                                              ? 'Mfuko'
                                                              : (t.category == 'HELB'
                                                                  ? 'HELB'
                                                                  : (t.category == 'Side hustle'
                                                                      ? 'Kazi ya kando'
                                                                      : (t.category == 'Gift'
                                                                          ? 'Zawadi'
                                                                          : 'Nyingine'))))))))))),
                          style: const TextStyle(
                              color: TCC.textMuted, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('h:mm a').format(t.date),
                          style: const TextStyle(
                              color: TCC.textDisabled, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${income ? '+' : '−'}${_kes(t.amount.abs())}',
              style: TextStyle(
                color: income ? TCC.hustle : TCC.danger,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
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
