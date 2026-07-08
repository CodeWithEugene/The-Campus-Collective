import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../theme/tokens.dart';

/// P06 — 4-tab bottom-nav shell (project.md §16.2).
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _index(BuildContext context, List<(String, IconData, IconData, String)> tabs) {
    final loc = GoRouterState.of(context).uri.path;
    final i = tabs.indexWhere((t) => loc.startsWith(t.$1));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final tabs = [
      ('/chat', Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
      ('/hustle', Icons.savings_rounded, Icons.savings_outlined, 
       switch (lang.flavor) {
         'english' => 'Finance',
         'sheng' => 'Hustle',
         _ => 'Pesa',
       }),
      ('/ratiba', Icons.event_note_rounded, Icons.event_note_outlined, 
       switch (lang.flavor) {
         'english' => 'Schedule',
         _ => 'Ratiba',
       }),
      ('/mimi', Icons.person_rounded, Icons.person_outline_rounded, 
       switch (lang.flavor) {
         'english' => 'Me',
         _ => 'Mimi',
       }),
    ];

    final index = _index(context, tabs);
    return Scaffold(
      backgroundColor: TCC.bg,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: TCC.bg,
          border: Border(top: BorderSide(color: TCC.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final t = tabs[i];
                final active = i == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(t.$1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(active ? t.$2 : t.$3,
                            color: active ? TCC.accent : TCC.textMuted, size: 24),
                        const SizedBox(height: 4),
                        Text(t.$4,
                            style: TextStyle(
                                color: active ? TCC.accent : TCC.textMuted,
                                fontSize: 11,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

