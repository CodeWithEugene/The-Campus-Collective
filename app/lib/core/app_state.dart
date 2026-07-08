import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import '../llm/flutter_gemma_service.dart';
import '../llm/gemma_service.dart';

/// Singletons.
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final gemmaProvider = Provider<GemmaService>((ref) {
  // Real on-device Gemma 4 via flutter_gemma (LiteRT-LM). StubGemmaService
  // remains available for widget tests.
  final g = FlutterGemmaService();
  ref.onDispose(g.dispose);
  return g;
});

final prefsProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Model presence + first-run flags (drives boot routing, project.md P01/P45).
class AppFlags {
  final bool onboarded;
  final bool modelReady;
  final bool disclaimerSeen;
  const AppFlags({
    this.onboarded = false,
    this.modelReady = false,
    this.disclaimerSeen = false,
  });

  AppFlags copyWith({bool? onboarded, bool? modelReady, bool? disclaimerSeen}) => AppFlags(
    onboarded: onboarded ?? this.onboarded,
    modelReady: modelReady ?? this.modelReady,
    disclaimerSeen: disclaimerSeen ?? this.disclaimerSeen,
  );
}

class AppFlagsNotifier extends StateNotifier<AppFlags> {
  final SharedPreferences prefs;
  AppFlagsNotifier(this.prefs)
    : super(AppFlags(
        onboarded: prefs.getBool('onboarded') ?? false,
        modelReady: prefs.getBool('modelReady') ?? false,
        disclaimerSeen: prefs.getBool('disclaimerSeen') ?? false,
      ));

  Future<void> setOnboarded(bool v) async {
    await prefs.setBool('onboarded', v);
    state = state.copyWith(onboarded: v);
  }

  Future<void> setModelReady(bool v) async {
    await prefs.setBool('modelReady', v);
    state = state.copyWith(modelReady: v);
  }

  Future<void> setDisclaimerSeen(bool v) async {
    await prefs.setBool('disclaimerSeen', v);
    state = state.copyWith(disclaimerSeen: v);
  }
}

final appFlagsProvider = StateNotifierProvider<AppFlagsNotifier, AppFlags>((ref) {
  final prefs = ref.watch(prefsProvider).valueOrNull;
  return AppFlagsNotifier(prefs!);
});

/// Language & greeting preference (project.md P38). Persisted so a change
/// survives app restarts.
class LangPref {
  final String flavor; // english|swahili|sheng
  final bool kiembuGreetings;
  const LangPref({this.flavor = 'english', this.kiembuGreetings = false});

  bool get isEnglish => flavor == 'english';
  bool get isSheng => flavor == 'sheng';

  LangPref copyWith({String? flavor, bool? kiembuGreetings}) => LangPref(
    flavor: flavor ?? this.flavor,
    kiembuGreetings: kiembuGreetings ?? this.kiembuGreetings,
  );
}

class LangNotifier extends StateNotifier<LangPref> {
  final SharedPreferences prefs;
  LangNotifier(this.prefs)
    : super(LangPref(
        flavor: prefs.getString('langFlavor') ?? 'english',
        kiembuGreetings: prefs.getBool('kiembuGreetings') ?? false,
      ));

  Future<void> setFlavor(String flavor) async {
    await prefs.setString('langFlavor', flavor);
    state = state.copyWith(flavor: flavor);
  }

  Future<void> setKiembuGreetings(bool v) async {
    await prefs.setBool('kiembuGreetings', v);
    state = state.copyWith(kiembuGreetings: v);
  }
}

final langProvider = StateNotifierProvider<LangNotifier, LangPref>((ref) {
  final prefs = ref.watch(prefsProvider).valueOrNull;
  return LangNotifier(prefs!);
});
