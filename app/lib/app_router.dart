import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/onboarding_screens.dart';
import 'features/onboarding/model_download_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/camera_screen.dart';
import 'features/chat/photo_review_screen.dart';
import 'features/somo/somo_result_screen.dart';
import 'features/somo/quiz_screen.dart';
import 'features/somo/flashcard_screen.dart';
import 'features/karani/karani_doc_screen.dart';
import 'features/hustle/hustle_dashboard.dart';
import 'features/hustle/budget_wizard.dart';
import 'features/hustle/transactions_screen.dart';
import 'features/hustle/transaction_edit.dart';
import 'features/hustle/insights_screen.dart';
import 'features/hustle/copywriter_screen.dart';
import 'features/ratiba/ratiba_today.dart';
import 'features/ratiba/task_list_screen.dart';
import 'features/ratiba/task_edit_screen.dart';
import 'features/ratiba/deadline_list_screen.dart';
import 'features/ratiba/timetable_screen.dart';
import 'features/mimi/mimi_hub.dart';
import 'features/mimi/library_screen.dart';
import 'features/mimi/scan_detail_screen.dart';
import 'features/mimi/safety_screen.dart';
import 'features/settings/settings_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding/1', builder: (c, s) => const OnboardingWhat()),
      GoRoute(path: '/onboarding/2', builder: (c, s) => const OnboardingWhy()),
      GoRoute(path: '/onboarding/model', builder: (c, s) => const ModelDownloadScreen()),

      // Main shell with 4 tabs
      ShellRoute(
        builder: (c, s, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
          GoRoute(path: '/hustle', builder: (c, s) => const HustleDashboard()),
          GoRoute(path: '/ratiba', builder: (c, s) => const RatibaToday()),
          GoRoute(path: '/mimi', builder: (c, s) => const MimiHub()),
        ],
      ),

      // Chat sub-flows
      GoRoute(
        path: '/scan/camera',
        builder: (c, s) => CameraScreen(intent: s.uri.queryParameters['intent'] ?? 'somo'),
      ),
      GoRoute(
        path: '/scan/review',
        builder: (c, s) => PhotoReviewScreen(
          imagePath: s.uri.queryParameters['path'] ?? '',
          intent: s.uri.queryParameters['intent'] ?? 'somo',
        ),
      ),

      // Somo results
      GoRoute(path: '/somo/result', builder: (c, s) => SomoResultScreen(scanId: s.uri.queryParameters['id'])),
      GoRoute(path: '/somo/quiz', builder: (c, s) => QuizScreen(scanId: s.uri.queryParameters['id'])),
      GoRoute(path: '/somo/flashcards', builder: (c, s) => FlashcardScreen(scanId: s.uri.queryParameters['id'])),

      // Karani
      GoRoute(path: '/karani/doc', builder: (c, s) => KaraniDocScreen(scanId: s.uri.queryParameters['id'])),

      // Hustle
      GoRoute(path: '/hustle/budget/new', builder: (c, s) => const BudgetWizard()),
      GoRoute(path: '/hustle/transactions', builder: (c, s) => const TransactionsScreen()),
      GoRoute(path: '/hustle/transactions/edit', builder: (c, s) => TransactionEdit(
        id: s.uri.queryParameters['id'],
        scanId: s.uri.queryParameters['scanId'],
      )),
      GoRoute(path: '/hustle/insights', builder: (c, s) => const InsightsScreen()),
      GoRoute(path: '/hustle/copywriter', builder: (c, s) => const CopywriterScreen()),

      // Ratiba
      GoRoute(path: '/ratiba/tasks', builder: (c, s) => const TaskListScreen()),
      GoRoute(path: '/ratiba/tasks/edit', builder: (c, s) => TaskEditScreen(id: s.uri.queryParameters['id'])),
      GoRoute(path: '/ratiba/deadlines', builder: (c, s) => const DeadlineListScreen()),
      GoRoute(path: '/ratiba/timetable', builder: (c, s) => TimetableScreen(scanId: s.uri.queryParameters['scanId'])),

      // Mimi / Library / Safety / Settings
      GoRoute(path: '/library', builder: (c, s) => const LibraryScreen()),
      GoRoute(path: '/library/scan', builder: (c, s) => ScanDetailScreen(id: s.uri.queryParameters['id'])),
      GoRoute(path: '/safety', builder: (c, s) => const SafetyScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsRoot()),
      GoRoute(path: '/settings/language', builder: (c, s) => const LanguageSettings()),
      GoRoute(path: '/settings/model', builder: (c, s) => const ModelSettings()),
      GoRoute(path: '/settings/notifications', builder: (c, s) => const NotificationSettings()),
      GoRoute(path: '/settings/privacy', builder: (c, s) => const PrivacySettings()),
      GoRoute(path: '/settings/about', builder: (c, s) => const AboutScreen()),
      GoRoute(path: '/settings/help', builder: (c, s) => const HelpScreen()),
      GoRoute(path: '/settings/report', builder: (c, s) => const ReportScreen()),
    ],
  );
});
