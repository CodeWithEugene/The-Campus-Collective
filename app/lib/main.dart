import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'core/app_state.dart';
import 'core/config.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: TCC.bg,
  ));

  // Backend is distribution-only; failure to reach it must never block the app.
  try {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseAnonKey,
    );
  } catch (_) {
    // Offline-first: continue with bundled content.
  }

  runApp(const ProviderScope(child: CampusCollectiveApp()));
}

class CampusCollectiveApp extends ConsumerWidget {
  const CampusCollectiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    return prefs.when(
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: TCC.bg),
      ),
      error: (_, _) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: TCC.bg),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'The Campus Collective',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: router,
        );
      },
    );
  }
}
