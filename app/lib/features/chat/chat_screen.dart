import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/app_state.dart';
import '../../data/content_service.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';
import 'chat_controller.dart';
import 'chat_models.dart';

/// P07 — the unified router chat: the heart of the app.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();
  String _greeting = 'Wĩ mwega!';
  bool _recording = false;
  bool _transcribing = false;

  @override
  void initState() {
    super.initState();
    ref.read(contentServiceProvider).kiembuGreeting().then((g) {
      if (mounted) setState(() => _greeting = g);
    });
  }

  void _send({String? forceAgent}) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(chatProvider.notifier).send(text, forceAgent: forceAgent);
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final lang = ref.watch(langProvider);
    ref.listen(chatProvider, (_, _) => _scrollDown());

    return TccScaffold(
      showBack: false,
      title: 'TCC',
      actions: [
        IconButton(
          tooltip: lang.flavor == 'english' ? 'New chat' : 'Chat mpya',
          icon: const Icon(Icons.add_comment_outlined, color: TCC.textMuted),
          onPressed: () => ref.read(chatProvider.notifier).newChat(),
        ),
        IconButton(
          tooltip: lang.flavor == 'english' ? 'Chat history' : 'Historia',
          icon: const Icon(Icons.history_rounded, color: TCC.textMuted),
          onPressed: _historySheet,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: TCC.textMuted),
          onPressed: () => context.go('/mimi'),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _emptyState(lang)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (c, i) => _bubble(messages[i]),
                  ),
          ),
          _composer(lang),
        ],
      ),
    );
  }

  Widget _emptyState(LangPref lang) {
    final greeting = lang.kiembuGreetings
        ? _greeting
        : switch (lang.flavor) {
            'english' => 'Hello',
            'sheng' => 'Niaje',
            _ => 'Habari',
          };

    final subtitle = switch (lang.flavor) {
      'english' => 'I am TCC. You can ask me about classes, finance, schedule, or campus bureaucracy.',
      'sheng' => 'Mimi ni TCC. Unaweza niuliza kuhusu masomo, pesa, ratiba ama makaratasi ya chuo.',
      _ => 'Mimi ni TCC. Kuniuliza maswali kuhusu masomo, fedha, ratiba au makaratasi ya chuo.',
    };

    final chips = switch (lang.flavor) {
      'english' => [
          ('📸 Scan notes', 'somo', Icons.menu_book_rounded),
          ('📄 Fee statement', 'karani', Icons.description_rounded),
          ('💰 Create budget', 'hustle', Icons.savings_rounded),
          ('🗓️ Plan my day', 'ratiba', Icons.event_note_rounded),
        ],
      'sheng' => [
          ('📸 Soma notes', 'somo', Icons.menu_book_rounded),
          ('📄 Fee statement', 'karani', Icons.description_rounded),
          ('💰 Tengeneza budget', 'hustle', Icons.savings_rounded),
          ('🗓️ Panga siku yangu', 'ratiba', Icons.event_note_rounded),
        ],
      _ => [
          ('📸 Soma maelezo', 'somo', Icons.menu_book_rounded),
          ('📄 Kauli ya ada', 'karani', Icons.description_rounded),
          ('💰 Tengeneza bajeti', 'hustle', Icons.savings_rounded),
          ('🗓️ Panga siku yangu', 'ratiba', Icons.event_note_rounded),
        ],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text('$greeting 👋',
              style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: chips.map((c) {
              return TccChip(
                label: c.$1,
                tint: TCC.agentColor(c.$2),
                onTap: () {
                  if (c.$2 == 'somo' || c.$2 == 'karani') {
                    context.push('/scan/camera?intent=${c.$2}');
                  } else if (c.$2 == 'hustle') {
                    context.go('/hustle');
                  } else {
                    context.go('/ratiba');
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMsg m) {
    if (m.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 8, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: TCC.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (m.imagePath != null && File(m.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(m.imagePath!), width: 160, fit: BoxFit.cover),
                ),
              if (m.content.isNotEmpty)
                Text(m.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
      );
    }
    final agent = m.agent ?? 'router';
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Row(
              children: [
                AgentAvatar(agent, size: 24),
                const SizedBox(width: 8),
                Text(agent[0].toUpperCase() + agent.substring(1),
                    style: TextStyle(
                        color: TCC.agentColor(agent), fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TCC.surface2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: TCC.border),
            ),
            child: m.content.isEmpty
                ? const Text('…',
                    style: TextStyle(color: TCC.text, fontSize: 15, height: 1.45))
                // Markdown-rendered: the model speaks **bold**, lists & headers.
                : GptMarkdown(
                    m.content,
                    style: const TextStyle(
                        color: TCC.text, fontSize: 15, height: 1.45),
                  ),
          ),
          if (m.lowConfidence)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 48),
              child: LowConfidenceBanner(onFindContacts: () => context.push('/safety')),
            ),
        ],
      ),
    );
  }

  Widget _composer(LangPref lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: TCC.bg,
        border: Border(top: BorderSide(color: TCC.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: TCC.textMuted),
            onPressed: _attachSheet,
          ),
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: _recording
                    ? (lang.flavor == 'english'
                        ? 'Listening… tap ■ when done'
                        : 'Nasikiliza… gusa ■ ukimaliza')
                    : _transcribing
                        ? (lang.flavor == 'english'
                            ? 'Transcribing…'
                            : 'Inaandika…')
                        : switch (lang.flavor) {
                            'english' => 'Ask anything...',
                            'sheng' => 'Uliza chochote...',
                            _ => 'Uliza chochote...',
                          },
              ),
            ),
          ),
          IconButton(
            tooltip: lang.flavor == 'english' ? 'Voice prompt' : 'Tumia sauti',
            onPressed: _transcribing ? null : _toggleVoice,
            icon: _transcribing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: TCC.accent),
                  )
                : Icon(
                    _recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                    color: _recording ? TCC.danger : TCC.textMuted,
                  ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: TCC.accent, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _historySheet() {
    final lang = ref.read(langProvider);
    final en = lang.flavor == 'english';
    showModalBottomSheet(
      context: context,
      backgroundColor: TCC.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final convs = ref.watch(conversationsProvider);
            final currentId = ref.watch(chatProvider.notifier).conversationId;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Text(en ? 'Chats' : 'Chats zako',
                          style: const TextStyle(
                              color: TCC.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          ref.read(chatProvider.notifier).newChat();
                          Navigator.pop(c);
                        },
                        icon: const Icon(Icons.add_rounded,
                            size: 18, color: TCC.accent),
                        label: Text(en ? 'New chat' : 'Chat mpya',
                            style: const TextStyle(color: TCC.accent)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: convs.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: TCC.accent),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (rows) => rows.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                en
                                    ? 'No chats yet — say hi!'
                                    : 'Hakuna chats bado — anza!',
                                style: const TextStyle(color: TCC.textMuted)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final conv = rows[i];
                              return ListTile(
                                leading: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: conv.id == currentId
                                      ? TCC.accent
                                      : TCC.textMuted,
                                ),
                                title: Text(conv.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: TCC.text,
                                        fontWeight: conv.id == currentId
                                            ? FontWeight.w700
                                            : FontWeight.w400)),
                                subtitle: Text(
                                    DateFormat('d MMM, HH:mm')
                                        .format(conv.updatedAt),
                                    style: const TextStyle(
                                        color: TCC.textMuted, fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 20, color: TCC.textMuted),
                                  onPressed: () => ref
                                      .read(chatProvider.notifier)
                                      .deleteConversation(conv.id),
                                ),
                                onTap: () {
                                  ref.read(chatProvider.notifier).open(conv.id);
                                  Navigator.pop(c);
                                },
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleVoice() async {
    final lang = ref.read(langProvider);
    final en = lang.flavor == 'english';
    if (_transcribing) return;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _transcribing = true;
      });
      String text = '';
      if (path != null) {
        text = await ref.read(gemmaProvider).transcribe(path);
        try {
          await File(path).delete();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _transcribing = false);
      if (text.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(en
                  ? "Didn't catch that — try again closer to the mic."
                  : 'Sikusikia vizuri — jaribu tena karibu na mic.')));
        return;
      }
      _input.text = _input.text.isEmpty ? text : '${_input.text} $text';
      _input.selection =
          TextSelection.collapsed(offset: _input.text.length);
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(en
                ? 'Microphone permission is needed for voice prompts.'
                : 'Ruhusa ya mic inahitajika kutumia sauti.')));
      return;
    }
    final dir = await getTemporaryDirectory();
    // Gemma's audio executor expects 16 kHz mono WAV.
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: p.join(dir.path, 'voice_prompt.wav'),
    );
    if (mounted) setState(() => _recording = true);
  }

  void _attachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: TCC.accent),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(c);
                context.push('/scan/camera?intent=somo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: TCC.accent),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(c);
                context.push('/scan/camera?intent=somo');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _recorder.dispose();
    super.dispose();
  }
}
