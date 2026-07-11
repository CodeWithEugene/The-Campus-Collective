import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/config.dart';
import 'gemma_service.dart';

/// Real on-device implementation of [GemmaService] using flutter_gemma 1.2.2
/// (LiteRT-LM). The model is a Gemma 4 `.litertlm` downloaded on first run by
/// [ModelDownloadNotifier] via the plugin's ModelFileManager; everything here
/// runs offline on the phone.
class FlutterGemmaService implements GemmaService {
  final _plugin = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceChat? _chat;
  Future<void>? _initFuture;

  /// The LiteRT-LM engine holds ONE live native conversation (upstream #966):
  /// every [_oneShot] createSession closes the chat's conversation out from
  /// under it, and the next generate throws "Bad state: Session is closed".
  /// Set after each one-shot; [chat] rebuilds its session (replaying history)
  /// before generating.
  bool _chatSessionStale = false;

  /// Single source of truth for which model the app runs. Shared with the
  /// download flow so "what we download" and "what we load" can never drift.
  static InferenceModelSpec get modelSpec => InferenceModelSpec.fromLegacyUrl(
        name: Config.defaultModelVersion,
        modelUrl: Config.defaultModelUrl,
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      );

  @override
  Future<bool> get isModelReady async {
    try {
      return await _plugin.modelManager.isModelInstalled(modelSpec);
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureInit() {
    // A failed init must not be cached: `??=` would pin the failed Future and
    // brick every AI feature until app restart over one transient error
    // (memory pressure, backend hiccup).
    final future = _initFuture ??= _init();
    future.catchError((_) {
      if (identical(_initFuture, future)) _initFuture = null;
    });
    return future;
  }

  Future<void> _init() async {
    _plugin.modelManager.setActiveModel(modelSpec);
    try {
      _model = await _createModel(PreferredBackend.gpu);
    } catch (_) {
      // The engine's own gpu→cpu fallback only catches `Exception`s; a
      // dlopen/allocation `Error` skips it. Retry CPU explicitly — plugin
      // resets its singleton state on createModel failure, so this is safe.
      _model = await _createModel(PreferredBackend.cpu);
    }
    _chat = await _model!.createChat(
      temperature: 0.7,
      topK: 40,
      supportImage: true,
      // Short answers stream fast even at CPU-fallback speeds.
      maxOutputTokens: 512,
    );
  }

  Future<InferenceModel> _createModel(PreferredBackend backend) =>
      _plugin.createModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
        // KV-cache budget shared by prompt + history + output. 2048 leaves room
        // for RAG chunks while staying safe on 6 GB devices.
        maxTokens: 2048,
        preferredBackend: backend,
        supportImage: true,
        maxNumImages: 1, // vision hygiene: one image per turn (project.md §8)
      );

  @override
  Stream<String> chat(String prompt, {String? imagePath, String? agent}) async* {
    try {
      await _ensureInit();
      final chat = _chat!;
      if (_chatSessionStale) {
        // fullHistory is a snapshot copy, so it survives the clear inside.
        await chat.clearHistory(replayHistory: chat.fullHistory);
        _chatSessionStale = false;
      }
      final text = '${_systemFor(agent)}\n\n$prompt';
      if (imagePath != null) {
        await chat.addQueryChunk(Message.withImage(
          text: text,
          imageBytes: await File(imagePath).readAsBytes(),
          isUser: true,
        ));
      } else {
        await chat.addQueryChunk(Message.text(text: text, isUser: true));
      }
      await for (final r in chat.generateChatResponseAsync()) {
        if (r is TextResponse) yield r.token;
      }
    } catch (e) {
      // ChatController has no catch around this stream (P56 inline-retry UX):
      // never throw, always end with a usable message. The engine error rides
      // along so on-device failures are diagnosable from a screenshot.
      yield 'Samahani — sikuweza kumaliza hiyo. Jaribu tena.\n\n⚙️ $e';
    }
  }

  @override
  Future<String> route(String text) async {
    try {
      final out = await _oneShot(
        'Classify this student message into exactly one of: somo, karani, '
        'hustle, ratiba. somo=studying/notes/quizzes, karani=fees/HELB/campus '
        'documents/offices, hustle=money/budget/M-Pesa/business, ratiba=time/'
        'tasks/deadlines/planning. Reply with only the label.\n\nMessage: $text',
      );
      final m = RegExp('somo|karani|hustle|ratiba').firstMatch(out.toLowerCase());
      return m?.group(0) ?? 'somo';
    } catch (_) {
      return _keywordRoute(text); // deterministic fallback (project.md §13)
    }
  }

  @override
  Future<Map<String, dynamic>> structured(
    String prompt, {
    String? imagePath,
    required String schemaHint,
  }) async {
    try {
      final out = await _oneShot(
        '$prompt\n\nRespond with ONLY valid minified JSON for a "$schemaHint" '
        'result. No prose, no markdown fences.',
        imagePath: imagePath,
      );
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(out);
      if (match == null) return {};
      return jsonDecode(match.group(0)!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// One-off low-temperature session so routing/extraction prompts never
  /// pollute the running chat history.
  Future<String> _oneShot(String prompt, {String? imagePath}) async {
    await _ensureInit();
    // Flag BEFORE creating: createSession closes the chat's conversation
    // first thing, so even a failed create leaves the chat session dead.
    _chatSessionStale = true;
    final session = await _model!.createSession(temperature: 0.1, topK: 1);
    try {
      if (imagePath != null) {
        await session.addQueryChunk(Message.withImage(
          text: prompt,
          imageBytes: await File(imagePath).readAsBytes(),
          isUser: true,
        ));
      } else {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      }
      return await session.getResponse();
    } finally {
      await session.close();
    }
  }

  String _keywordRoute(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'pesa|budget|mpesa|m-pesa|bei|fare|matatu|biashara|hustle')
        .hasMatch(t)) {
      return 'hustle';
    }
    if (RegExp(r'fee|helb|hef|balance|statement|hostel|barua|ofisi').hasMatch(t)) {
      return 'karani';
    }
    if (RegExp(r'plan|panga|deadline|task|ratiba|timetable|leo|kesho').hasMatch(t)) {
      return 'ratiba';
    }
    return 'somo';
  }

  String _systemFor(String? agent) {
    final persona = switch (agent) {
      'hustle' =>
        'You are Hustle, TCC\'s money agent for University of Embu students. '
            'Be practical about student finances (HELB, M-Pesa, side hustles).',
      'karani' =>
        'You are Karani, TCC\'s bureaucracy agent. Explain campus documents '
            'simply, extract deadlines, and remind users to verify with the office.',
      'ratiba' => 'You are Ratiba, TCC\'s day planner. Be brief and actionable.',
      _ => 'You are Somo, TCC\'s study helper. Summarize clearly and quiz kindly.',
    };
    return '$persona Reply in the user\'s language mix (English, Kiswahili or '
        'Sheng). Keep answers short.';
  }

  @override
  void dispose() {
    _chat = null;
    _model?.close();
    _model = null;
    _initFuture = null;
  }
}
