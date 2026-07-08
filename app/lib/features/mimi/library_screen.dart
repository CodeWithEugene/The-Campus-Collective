import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P33 — Library: every scan the user has saved, filterable & searchable.
/// Reads straight off the Scans drift table so it stays live.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _filter = 'all'; // all|somo|karani|receipt|timetable

  static const _filters = ['all', 'somo', 'karani', 'receipt', 'timetable'];

  String _segLabel(L t, String key) => switch (key) {
        'somo' => t.filterNotes,
        'karani' => t.filterDocs,
        'receipt' => t.filterReceipts,
        'timetable' => t.filterTimetables,
        _ => t.filterAll,
      };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(dbProvider);
    final t = ref.l10n;

    return TccScaffold(
      title: t.library,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: t.searchScans,
                prefixIcon: const Icon(Icons.search_rounded, color: TCC.textMuted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: TCC.textMuted),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final key = _filters[i];
                return TccChip(
                  label: _segLabel(t, key),
                  selected: _filter == key,
                  tint: _tintFor(key),
                  onTap: () => setState(() => _filter = key),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<Scan>>(
              stream: db.select(db.scans).watch(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: TCC.accent),
                  );
                }
                var scans = snap.data!;
                if (_filter != 'all') {
                  scans = scans.where((s) => s.type == _filter).toList();
                }
                if (_query.isNotEmpty) {
                  scans = scans
                      .where((s) => s.title.toLowerCase().contains(_query))
                      .toList();
                }
                scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (scans.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_open_rounded,
                    title: t.nothingHere,
                    subtitle: t.scansLiveHere,
                    action: FilledButton.icon(
                      onPressed: () => context.push('/scan/camera?intent=somo'),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(t.scanSomething),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: scans.length,
                  itemBuilder: (c, i) => _scanCard(context, t, scans[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanCard(BuildContext context, L t, Scan s) {
    final tint = _tintFor(s.type);
    final date = DateFormat('d MMM, HH:mm').format(s.createdAt);
    return TccCard(
      onTap: () => context.push('/library/scan?id=${s.id}'),
      borderColor: tint.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(s.type), color: tint, size: 22),
          ),
          const Spacer(),
          Text(
            s.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: TCC.text, fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(_labelFor(t, s.type),
                  style: TextStyle(
                      color: tint, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(date,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: TCC.textMuted, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _tintFor(String type) => switch (type) {
        'somo' => TCC.somo,
        'karani' => TCC.karani,
        'receipt' => TCC.hustle,
        'timetable' => TCC.ratiba,
        _ => TCC.accent,
      };

  IconData _iconFor(String type) => switch (type) {
        'somo' => Icons.menu_book_rounded,
        'karani' => Icons.description_rounded,
        'receipt' => Icons.receipt_long_rounded,
        'timetable' => Icons.calendar_view_week_rounded,
        _ => Icons.insert_drive_file_rounded,
      };

  String _labelFor(L t, String type) => switch (type) {
        'somo' => t.typeNote,
        'karani' => t.typeDoc,
        'receipt' => t.typeReceipt,
        'timetable' => t.timetable,
        _ => t.typeScan,
      };
}
