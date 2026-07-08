import 'dart:async';
import 'dart:convert';

/// Abstraction over the on-device Gemma 4 model.
///
/// The real implementation wraps `flutter_gemma` (validated on-device — see
/// project.md §8/§9). Until that validation passes, [StubGemmaService] provides
/// deterministic, offline, demo-quality responses so the whole app builds, runs,
/// and is navigable end-to-end. The rest of the app depends ONLY on this
/// interface, so swapping in the real engine touches no UI (project.md discipline:
/// "the app must work end-to-end on stock E2B first").
abstract class GemmaService {
  Future<bool> get isModelReady;

  /// Stream a plain text answer token-by-token.
  Stream<String> chat(String prompt, {String? imagePath, String? agent});

  /// Ask the model to route free text to an agent.
  Future<String> route(String text);

  /// Run a tool-calling turn; returns the decoded structured result.
  Future<Map<String, dynamic>> structured(
    String prompt, {
    String? imagePath,
    required String schemaHint,
  });

  void dispose() {}
}

/// Deterministic offline stub. Produces believable, agent-appropriate output.
class StubGemmaService implements GemmaService {
  @override
  Future<bool> get isModelReady async => true;

  @override
  Stream<String> chat(String prompt, {String? imagePath, String? agent}) async* {
    final reply = _canned(prompt, agent);
    for (final word in reply.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 28));
      yield '$word ';
    }
  }

  @override
  Future<String> route(String text) async {
    final t = text.toLowerCase();
    if (RegExp(r'budget|pesa|mpesa|expense|hustle|fare|matatu|money|shilling|ksh').hasMatch(t)) {
      return 'hustle';
    }
    if (RegExp(r'plan|ratiba|day|task|deadline|timetable|remind|schedule').hasMatch(t)) {
      return 'ratiba';
    }
    if (RegExp(r'fee|helb|hef|form|letter|hostel|document|karani|office').hasMatch(t)) {
      return 'karani';
    }
    return 'somo';
  }

  @override
  Future<Map<String, dynamic>> structured(
    String prompt, {
    String? imagePath,
    required String schemaHint,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Return schema-shaped placeholder data so result views render.
    return jsonDecode(_stubStructured(schemaHint)) as Map<String, dynamic>;
  }

  String _canned(String prompt, String? agent) {
    switch (agent) {
      case 'hustle':
        return 'Poa! Nimeangalia budget yako. Kwa hii wiki uko na KSh 8,420 zimebaki. '
            'Ukituma KSh 1,200 kwa M-Pesa utakatwa KSh 23. Tumia Wi-Fi ya chuo ukiweza. '
            '(Demo mode: connect the on-device model for full answers.)';
      case 'ratiba':
        return 'Sawa, nimepanga siku yako: madarasa mawili, deadline moja (HELB form, siku 4 zimebaki), '
            'na tasks tatu. Ningeanza na assignment ya asubuhi. (Demo mode.)';
      case 'karani':
        return 'Hii inaonekana ni fee statement. Balance ni KSh 12,400, due tarehe 15 Aug. '
            'Thibitisha na ofisi ya finance kabla ya kulipa. (Demo mode.)';
      default:
        return 'Nimesoma notes zako. Hapa kuna muhtasari mfupi na maswali ya kujitest. '
            'Kwa lugha rahisi: focus kwa main points, halafu jaribu quiz. (Demo mode.)';
    }
  }

  String _stubStructured(String schemaHint) {
    if (schemaHint.contains('receipt')) {
      return jsonEncode({
        'merchant': 'Naivas Supermarket',
        'amount': 1850.0,
        'category': 'Food',
        'date': '2026-07-05',
        'confidence': 0.95,
      });
    }
    if (schemaHint.contains('timetable')) {
      return jsonEncode({
        'classes': [
          {
            'unit': 'SCS 201: Systems Analysis & Design',
            'weekday': 1,
            'startTime': '08:00',
            'endTime': '10:00',
            'venue': 'LH 1',
            'lecturer': 'Dr. Erick Mwangi',
          },
          {
            'unit': 'SCS 203: Mobile App Development',
            'weekday': 3,
            'startTime': '11:00',
            'endTime': '13:00',
            'venue': 'Lab 3',
            'lecturer': 'Faith Kiprono',
          },
        ],
      });
    }
    if (schemaHint.contains('quiz')) {
      return jsonEncode({
        'summary': ['Key point one from your notes', 'Key point two', 'Key point three'],
        'simple': 'Kwa lugha rahisi: this topic is about the main idea and two supporting facts.',
        'quiz': [
          {
            'q': 'What is the main idea of the notes?',
            'options': ['Option A', 'Option B (correct)', 'Option C', 'Option D'],
            'answer': 1,
            'why': 'Because it captures the central concept.',
          },
        ],
        'flashcards': [
          {'front': 'Key term', 'back': 'Its definition'},
        ],
      });
    }
    if (schemaHint.contains('karani')) {
      return jsonEncode({
        'summary': 'Hii ni fee statement ya University of Embu.',
        'fields': {'Balance': 'KES 12,400', 'Due date': '15 Aug 2026'},
        'steps': ['Angalia balance', 'Lipa kupitia portal', 'Weka receipt'],
        'deadlines': [
          {'title': 'Fee balance due', 'dueAt': '2026-08-15'},
        ],
        'citations': [
          {'source': 'UoEm Fee Structure 2024/25', 'chunk': 'Balances are due before exam cards are issued.'},
        ],
        'confidence': 0.72,
        'topicSensitive': true,
      });
    }
    if (schemaHint.contains('budget')) {
      return jsonEncode({
        'income': 17000,
        'categories': [
          {'name': 'Food', 'limit': 6000},
          {'name': 'Rent', 'limit': 5000},
          {'name': 'Transport', 'limit': 2500},
          {'name': 'Data/Airtime', 'limit': 1500},
          {'name': 'Fun', 'limit': 2000},
        ],
      });
    }
    return jsonEncode({'text': 'Demo structured output.'});
  }

  @override
  void dispose() {}
}
