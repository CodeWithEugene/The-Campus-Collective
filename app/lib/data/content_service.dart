import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads bundled content packs (safety contacts, tariffs, fares, phrasebook,
/// corpus). Ships offline inside the APK; refreshed from Supabase when online
/// (project.md §17). For v1 the app reads the bundled copies directly.
class ContentService {
  final Map<String, dynamic> _cache = {};

  Future<Map<String, dynamic>> load(String kind) async {
    if (_cache.containsKey(kind)) return _cache[kind];
    final file = switch (kind) {
      'safety_contacts' => 'assets/content/safety_contacts.json',
      'mpesa_tariffs' => 'assets/content/mpesa_tariffs.json',
      'matatu_fares' => 'assets/content/matatu_fares.json',
      'kiembu_phrasebook' => 'assets/content/kiembu_phrasebook.json',
      'corpus' => 'assets/content/corpus_v1.json',
      _ => throw ArgumentError('unknown content kind $kind'),
    };
    final raw = await rootBundle.loadString(file);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _cache[kind] = data;
    return data;
  }

  /// M-Pesa send fee for an amount (project.md Hustle tool).
  Future<int> mpesaSendFee(num amount) async {
    final data = await load('mpesa_tariffs');
    for (final band in (data['send_to_mpesa_user'] as List)) {
      if (amount >= band['min'] && amount <= band['max']) return band['fee'] as int;
    }
    return 0;
  }

  /// Kiembu greeting for the UI (project.md P07 empty state).
  Future<String> kiembuGreeting() async {
    final data = await load('kiembu_phrasebook');
    final entries = data['entries'] as List;
    return entries.isNotEmpty ? entries.first['kiembu'] as String : 'Wĩ mwega!';
  }
}

final contentServiceProvider = Provider((_) => ContentService());
