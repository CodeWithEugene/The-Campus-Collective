import 'package:flutter/foundation.dart';

/// A single chat message shown in the router chat (project.md P07).
@immutable
class ChatMsg {
  final String role; // user | agent | system
  final String? agent; // somo | karani | hustle | ratiba | router
  final String content;
  final String? imagePath;
  final bool streaming;
  final bool lowConfidence;
  final Map<String, dynamic>? card; // inline result card payload

  const ChatMsg({
    required this.role,
    this.agent,
    required this.content,
    this.imagePath,
    this.streaming = false,
    this.lowConfidence = false,
    this.card,
  });

  ChatMsg copyWith({String? content, bool? streaming, bool? lowConfidence, Map<String, dynamic>? card}) =>
      ChatMsg(
        role: role,
        agent: agent,
        content: content ?? this.content,
        imagePath: imagePath,
        streaming: streaming ?? this.streaming,
        lowConfidence: lowConfidence ?? this.lowConfidence,
        card: card ?? this.card,
      );
}
