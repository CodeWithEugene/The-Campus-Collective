import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_state.dart';
import '../../data/database.dart';
import '../../llm/gemma_service.dart';
import 'chat_models.dart';

class ChatController extends StateNotifier<List<ChatMsg>> {
  final GemmaService gemma;
  final AppDatabase db;
  ChatController(this.gemma, this.db) : super(const []) {
    _hydrate();
  }

  /// Load persisted history so past conversations survive app restarts.
  Future<void> _hydrate() async {
    final rows = await (db.select(db.chatMessages)
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt), (m) => OrderingTerm.asc(m.id)]))
        .get();
    if (rows.isEmpty) return;
    final restored = rows
        .map((r) => ChatMsg(
              role: r.role,
              agent: r.agent,
              content: r.content,
              imagePath: r.imagePath,
              lowConfidence: r.confidence < 0.8,
              card: r.cardJson == null
                  ? null
                  : jsonDecode(r.cardJson!) as Map<String, dynamic>,
            ))
        .toList();
    // Live messages (if any arrived during the read) stay after history.
    state = [...restored, ...state];
  }

  Future<void> _persist(ChatMsg m) => db.into(db.chatMessages).insert(
        ChatMessagesCompanion.insert(
          role: m.role,
          agent: Value(m.agent),
          content: m.content,
          imagePath: Value(m.imagePath),
          cardJson: Value(m.card == null ? null : jsonEncode(m.card)),
          confidence: Value(m.lowConfidence ? 0.7 : 1),
        ),
      );

  Future<void> send(String text, {String? imagePath, String? forceAgent}) async {
    if (text.trim().isEmpty && imagePath == null) return;
    final userMsg = ChatMsg(role: 'user', content: text, imagePath: imagePath);
    state = [...state, userMsg];
    await _persist(userMsg);

    final agent = forceAgent ?? await gemma.route(text);
    final placeholder = ChatMsg(role: 'agent', agent: agent, content: '', streaming: true);
    state = [...state, placeholder];
    final idx = state.length - 1;

    final buffer = StringBuffer();
    await for (final chunk in gemma.chat(text, imagePath: imagePath, agent: agent)) {
      buffer.write(chunk);
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(content: buffer.toString());
      state = updated;
    }
    final updated = [...state];
    updated[idx] = updated[idx].copyWith(
      streaming: false,
      lowConfidence: agent == 'karani',
    );
    state = updated;
    if (updated[idx].content.isNotEmpty) await _persist(updated[idx]);
  }

  Future<void> reset() async {
    state = const [];
    await db.delete(db.chatMessages).go();
  }
}

final chatProvider = StateNotifierProvider<ChatController, List<ChatMsg>>(
  (ref) => ChatController(ref.watch(gemmaProvider), ref.watch(dbProvider)),
);
