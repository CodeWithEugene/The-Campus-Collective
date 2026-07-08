import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_state.dart';
import '../../llm/gemma_service.dart';
import 'chat_models.dart';

class ChatController extends StateNotifier<List<ChatMsg>> {
  final GemmaService gemma;
  ChatController(this.gemma) : super(const []);

  Future<void> send(String text, {String? imagePath, String? forceAgent}) async {
    if (text.trim().isEmpty && imagePath == null) return;
    state = [...state, ChatMsg(role: 'user', content: text, imagePath: imagePath)];

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
  }

  void reset() => state = const [];
}

final chatProvider = StateNotifierProvider<ChatController, List<ChatMsg>>(
  (ref) => ChatController(ref.watch(gemmaProvider)),
);
