import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _greeting = 'Wĩ mwega!';

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
            child: Text(
              m.content.isEmpty ? '…' : m.content,
              style: const TextStyle(color: TCC.text, fontSize: 15, height: 1.45),
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
                hintText: switch (lang.flavor) {
                  'english' => 'Ask anything...',
                  'sheng' => 'Uliza chochote...',
                  _ => 'Uliza chochote...',
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
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
    super.dispose();
  }
}
