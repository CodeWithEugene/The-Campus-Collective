import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../core/l10n.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

/// P13 — Karani document decoded screen.
/// Shows plain-Swahili summary, structured fields, steps list, and citations
/// for photographed bureaucratic documents (fee statements, HELB letters, etc.)
class KaraniDocScreen extends ConsumerStatefulWidget {
  final String? scanId;
  const KaraniDocScreen({super.key, this.scanId});

  @override
  ConsumerState<KaraniDocScreen> createState() => _KaraniDocScreenState();
}

class _KaraniDocScreenState extends ConsumerState<KaraniDocScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final id = int.tryParse(widget.scanId ?? '');
    if (id != null) {
      final db = ref.read(dbProvider);
      final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null) {
        try {
          return jsonDecode(row.resultJson) as Map<String, dynamic>;
        } catch (_) {
          return {'_raw': row.resultJson};
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    return TccScaffold(
      title: lang.flavor == 'english' ? 'Clerk' : 'Karani',
      showLogo: true,
      actions: [
        IconButton(
          onPressed: () => context.push('/safety'),
          icon: const Icon(Icons.call_rounded, color: TCC.textMuted),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (c, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: TCC.accent));
          }
          final data = snap.data;
          if (data == null) {
            return EmptyState(
              icon: Icons.document_scanner_outlined,
              title: lang.flavor == 'english' ? 'No documents' : 'Hakuna nyaraka',
              subtitle: lang.flavor == 'english'
                  ? 'Take a photo of a statement, letter, or any form.'
                  : 'Piga picha ya statement, barua, au fomu yoyote.',
              action: FilledButton(
                onPressed: () => context.go('/chat'),
                child: Text(lang.flavor == 'english' ? 'Back to chat' : 'Rudi kwa chat'),
              ),
            );
          }

          final summary = data['summary'] as String? ?? '';
          final fields = (data['fields'] as Map<String, dynamic>?) ?? const {};
          final steps = (data['steps'] as List?)?.cast<String>() ?? const <String>[];
          final deadlines = (data['deadlines'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          final citations = (data['citations'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          final confidence = (data['confidence'] as num?)?.toDouble() ?? 1.0;
          final topicSensitive = data['topicSensitive'] as bool? ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // Summary card
              TccCard(
                borderColor: TCC.karani.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.flavor == 'english' ? 'Summary' : 'Muhtasari', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(summary,
                        style: const TextStyle(color: TCC.text, fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Structured fields
              if (fields.isNotEmpty) ...[
                SectionHeader(lang.flavor == 'english' ? 'Key details' : 'Maelezo muhimu'),
                TccCard(
                  child: Column(
                    children: fields.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text('${e.key}: ',
                                style: const TextStyle(
                                    color: TCC.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                            Expanded(
                                child: Text('${e.value}',
                                    style: const TextStyle(color: TCC.text, fontSize: 14))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Steps
              if (steps.isNotEmpty) ...[
                SectionHeader(lang.flavor == 'english' ? 'Steps to follow' : 'Hatua za kufuata'),
                ...steps.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: TCC.karani.withValues(alpha: 0.15),
                          child: Text('${e.key + 1}',
                              style: TextStyle(color: TCC.karani, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.value,
                              style: const TextStyle(color: TCC.text, fontSize: 15, height: 1.45)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Deadlines
              if (deadlines.isNotEmpty) ...[
                SectionHeader(lang.flavor == 'english' ? 'Important deadlines' : 'Muda muhimu'),
                ...deadlines.map((d) {
                  final title = d['title'] as String? ?? '';
                  final due = d['dueAt'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TccChip(
                      label: '$title  ·  $due',
                      icon: Icons.event_rounded,
                      tint: TCC.ratiba,
                      onTap: () async {
                        final db = ref.read(dbProvider);
                        final parsedDate = DateTime.tryParse(due) ?? DateTime.now();
                        await db.into(db.deadlines).insert(
                              DeadlinesCompanion.insert(
                                title: title,
                                dueAt: parsedDate,
                                sourceType: const Value('scan'),
                                sourceScanId: Value(int.tryParse(widget.scanId ?? '')),
                              ),
                            );
                        if (!context.mounted) return;
                        poa(context, ref.l10n.deadlineSaved);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Citations
              if (citations.isNotEmpty) ...[
                SectionHeader(lang.flavor == 'english' ? 'Sources' : 'Chanzo'),
                ...citations.map((c) {
                  final source = c['source'] as String? ?? '';
                  final chunk = c['chunk'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TccCard(
                      color: TCC.surface2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(source,
                              style: const TextStyle(color: TCC.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(chunk,
                              style: const TextStyle(color: TCC.textMuted, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Low confidence / topic sensitive banner
              if (topicSensitive || confidence < 0.75)
                LowConfidenceBanner(
                  onFindContacts: () => context.push('/safety'),
                ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        poa(context, ref.l10n.shared);
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(ref.l10n.share),
                      style: FilledButton.styleFrom(
                        backgroundColor: TCC.karani,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/chat'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: Text(lang.flavor == 'english' ? 'Back to chat' : 'Rudi kwa chat'),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: TCC.border)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
