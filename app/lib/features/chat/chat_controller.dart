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
    _hydrateLatest();
  }

  /// Conversation the visible messages belong to. Null until the first send
  /// of a fresh chat — the row is created lazily so empty chats never litter
  /// the history list.
  int? _conversationId;
  int? get conversationId => _conversationId;

  /// On app start, reopen the most recently active conversation.
  Future<void> _hydrateLatest() async {
    final last = await (db.select(db.conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (last != null) await open(last.id);
  }

  /// Load an existing conversation into the chat view.
  Future<void> open(int id) async {
    _conversationId = id;
    final rows = await (db.select(db.chatMessages)
          ..where((m) => m.conversationId.equals(id))
          ..orderBy([
            (m) => OrderingTerm.asc(m.createdAt),
            (m) => OrderingTerm.asc(m.id)
          ]))
        .get();
    state = rows
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
  }

  /// Start a fresh chat. The old conversation stays in history untouched.
  void newChat() {
    _conversationId = null;
    state = const [];
  }

  /// Delete a conversation and its messages. If it is the open one, the view
  /// becomes a fresh chat.
  Future<void> deleteConversation(int id) async {
    await (db.delete(db.chatMessages)
          ..where((m) => m.conversationId.equals(id)))
        .go();
    await (db.delete(db.conversations)..where((c) => c.id.equals(id))).go();
    if (_conversationId == id) newChat();
  }

  Future<int> _ensureConversation(String firstText) async {
    final existing = _conversationId;
    if (existing != null) return existing;
    final title = firstText.trim().isEmpty
        ? 'New chat'
        : (firstText.trim().length > 40
            ? '${firstText.trim().substring(0, 40)}…'
            : firstText.trim());
    final id = await db
        .into(db.conversations)
        .insert(ConversationsCompanion.insert(title: Value(title)));
    _conversationId = id;
    return id;
  }

  Future<void> _touchConversation(int id) =>
      (db.update(db.conversations)..where((c) => c.id.equals(id)))
          .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));

  Future<void> _persist(int conversationId, ChatMsg m) =>
      db.into(db.chatMessages).insert(
            ChatMessagesCompanion.insert(
              conversationId: Value(conversationId),
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
    final convId = await _ensureConversation(text);
    final userMsg = ChatMsg(role: 'user', content: text, imagePath: imagePath);
    state = [...state, userMsg];
    await _persist(convId, userMsg);
    await _touchConversation(convId);

    final agent = forceAgent ?? await gemma.route(text);
    var current = ChatMsg(role: 'agent', agent: agent, content: '', streaming: true);
    state = [...state, current];

    // Identity-based updates: the user can switch/create chats mid-stream, so
    // never trust a captured index into `state`.
    void swap(ChatMsg next) {
      final i = state.indexOf(current);
      if (i != -1) {
        final updated = [...state];
        updated[i] = next;
        state = updated;
      }
      current = next;
    }

    final buffer = StringBuffer();
    await for (final chunk in gemma.chat(text, imagePath: imagePath, agent: agent)) {
      buffer.write(chunk);
      if (_conversationId == convId) {
        swap(current.copyWith(content: buffer.toString()));
      }
    }
    final done = ChatMsg(
      role: 'agent',
      agent: agent,
      content: buffer.toString(),
      streaming: false,
      lowConfidence: agent == 'karani',
    );
    if (_conversationId == convId) swap(done);
    if (done.content.isNotEmpty) {
      await _persist(convId, done);
      await _touchConversation(convId);
    }
  }
}

final chatProvider = StateNotifierProvider<ChatController, List<ChatMsg>>(
  (ref) => ChatController(ref.watch(gemmaProvider), ref.watch(dbProvider)),
);

/// Live conversation list for the history sheet, newest activity first.
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.conversations)
        ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
      .watch();
});
