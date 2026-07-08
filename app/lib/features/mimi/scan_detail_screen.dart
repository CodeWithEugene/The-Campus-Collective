import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P34 — Scan detail: one saved scan, rendered generically from its stored
/// resultJson, with re-run / share / delete actions.
class ScanDetailScreen extends ConsumerWidget {
  final String? id;
  const ScanDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final t = ref.l10n;
    final scanId = int.tryParse(id ?? '');

    return TccScaffold(
      title: t.typeScan,
      body: scanId == null
          ? EmptyState(
              icon: Icons.error_outline_rounded,
              title: t.scanNotFound,
              subtitle: t.mayBeDeleted,
            )
          : FutureBuilder<Scan?>(
              future: (db.select(db.scans)
                    ..where((r) => r.id.equals(scanId)))
                  .getSingleOrNull(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: TCC.accent),
                  );
                }
                final scan = snap.data;
                if (scan == null) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: t.scanNotFound,
                    subtitle: t.mayBeDeleted,
                  );
                }
                return _body(context, ref, db, t, scan);
              },
            ),
    );
  }

  Widget _body(
      BuildContext context, WidgetRef ref, AppDatabase db, L t, Scan scan) {
    final tint = TCC.agentColor(scan.type);
    final date = DateFormat('EEEE d MMM yyyy · HH:mm').format(scan.createdAt);
    dynamic result;
    try {
      result = jsonDecode(scan.resultJson);
    } catch (_) {
      result = scan.resultJson;
    }

    final hasPhoto = scan.photoPath != null && File(scan.photoPath!).existsSync();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: tint.withValues(alpha: 0.4)),
              ),
              child: Icon(_iconFor(scan.type), color: tint, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scan.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(date,
                      style: const TextStyle(color: TCC.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (hasPhoto)
          ClipRRect(
            borderRadius: BorderRadius.circular(TCC.radius),
            child: Image.file(File(scan.photoPath!), fit: BoxFit.cover),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: TCC.surface2,
              borderRadius: BorderRadius.circular(TCC.radiusSm),
              border: Border.all(color: TCC.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, color: TCC.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.textOnlyNote,
                      style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        SectionHeader(t.result),
        _renderNode(context, result),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/scan/camera?intent=${scan.type}'),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t.rerun),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _share(scan),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(t.share),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, db, t, scan),
          style: OutlinedButton.styleFrom(
            foregroundColor: TCC.danger,
            side: BorderSide(color: TCC.danger.withValues(alpha: 0.5)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(t.delete),
        ),
      ],
    );
  }

  // ---- Generic JSON renderer ----

  Widget _renderNode(BuildContext context, dynamic node, {int depth = 0}) {
    if (node is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: node.entries.map((e) {
          final key = _humanize(e.key.toString());
          final value = e.value;
          if (value is Map || value is List) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12, left: depth > 0 ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key,
                      style: const TextStyle(
                          color: TCC.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _renderNode(context, value, depth: depth + 1),
                ],
              ),
            );
          }
          return _kvRow(key, _stringify(value));
        }).toList(),
      );
    }
    if (node is List) {
      if (node.isEmpty) {
        return const Text('—', style: TextStyle(color: TCC.textMuted));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: node.map((item) {
          if (item is Map || item is List) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TCC.surface,
                borderRadius: BorderRadius.circular(TCC.radiusSm),
                border: Border.all(color: TCC.border),
              ),
              child: _renderNode(context, item, depth: depth + 1),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 10),
                  child: Icon(Icons.circle, size: 6, color: TCC.accent),
                ),
                Expanded(
                  child: Text(_stringify(item),
                      style: const TextStyle(
                          color: TCC.text, fontSize: 14, height: 1.4)),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
    return Text(_stringify(node),
        style: const TextStyle(color: TCC.text, fontSize: 15, height: 1.5));
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k,
                style: const TextStyle(color: TCC.textMuted, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(v,
                style: const TextStyle(
                    color: TCC.text, fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }

  String _humanize(String key) {
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    if (spaced.isEmpty) return spaced;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _stringify(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    return v.toString();
  }

  void _share(Scan scan) {
    final buffer = StringBuffer()
      ..writeln(scan.title)
      ..writeln('— via The Campus Collective')
      ..writeln();
    try {
      final decoded = jsonDecode(scan.resultJson);
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(decoded));
    } catch (_) {
      buffer.writeln(scan.resultJson);
    }
    Share.share(buffer.toString(), subject: scan.title);
  }

  Future<void> _confirmDelete(
      BuildContext context, AppDatabase db, L t, Scan scan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: TCC.surface,
        title: Text(t.deleteScanQ),
        content: Text(t.deleteScanBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: TCC.danger),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await (db.delete(db.scans)..where((r) => r.id.equals(scan.id))).go();
    if (context.mounted) {
      poa(context, t.deletedDone);
      context.pop();
    }
  }

  IconData _iconFor(String type) => switch (type) {
        'somo' => Icons.menu_book_rounded,
        'karani' => Icons.description_rounded,
        'receipt' => Icons.receipt_long_rounded,
        'timetable' => Icons.calendar_view_week_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
}
