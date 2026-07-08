import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../ui/widgets.dart';

class _OnboardingScaffold extends StatelessWidget {
  final int step;
  final Widget content;
  final VoidCallback onNext;
  const _OnboardingScaffold({
    required this.step,
    required this.content,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TCC.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Action Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (step > 0)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: TCC.textMuted, size: 20),
                          onPressed: () => context.go('/onboarding/1'),
                        ),
                      if (step > 0) const SizedBox(width: 12),
                      SvgPicture.asset(
                        'assets/brand/logo_icon.svg',
                        width: 32,
                        height: 32,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/onboarding/model'),
                    style: TextButton.styleFrom(
                      foregroundColor: TCC.accent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              
              // Core screen view
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: content,
                  ),
                ),
              ),

              // Bottom control dock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step indicator dots
                  Row(
                    children: List.generate(3, (i) {
                      final active = i == step;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? TCC.accent : TCC.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  
                  // Next action button
                  SizedBox(
                    height: 50,
                    width: 140,
                    child: FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: TCC.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// P02 — "Meet your campus crew"
class OnboardingWhat extends ConsumerWidget {
  const OnboardingWhat({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final isEnglish = lang.flavor == 'english';

    final agents = [
      (
        isEnglish ? 'Study' : 'Somo',
        TCC.somo,
        Icons.menu_book_rounded,
        isEnglish ? 'Summaries & Quizzes' : 'Muhtasari na Quizzes'
      ),
      (
        isEnglish ? 'Clerk' : 'Karani',
        TCC.karani,
        Icons.description_rounded,
        isEnglish ? 'HELB statements & fees' : 'Kagua barua za HELB'
      ),
      (
        'Hustle',
        TCC.hustle,
        Icons.savings_rounded,
        isEnglish ? 'Budgets & Expense logs' : 'Bajeti na matumizi'
      ),
      (
        isEnglish ? 'Schedule' : 'Ratiba',
        TCC.ratiba,
        Icons.event_note_rounded,
        isEnglish ? 'Classes & Day planner' : 'Masomo na kalenda'
      ),
    ];

    return _OnboardingScaffold(
      step: 0,
      onNext: () => context.go('/onboarding/2'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'Meet your campus crew' : 'Kutana na wasaidizi wako',
            style: const TextStyle(
              color: TCC.text,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish
                ? 'Four specialized local AI helpers working together to simplify your college life.'
                : 'Wasaidizi wanne wa AI wanaofanya kazi kwa pamoja kurahisisha maisha yako ya chuo.',
            style: const TextStyle(color: TCC.textMuted, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 32),
          
          // 2x2 Agent Card Grid using Table/Rows
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _agentCard(agents[0])),
                  const SizedBox(width: 14),
                  Expanded(child: _agentCard(agents[1])),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _agentCard(agents[2])),
                  const SizedBox(width: 14),
                  Expanded(child: _agentCard(agents[3])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agentCard((String, Color, IconData, String) a) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TCC.surface,
        borderRadius: BorderRadius.circular(TCC.radius),
        border: Border.all(color: a.$2.withValues(alpha: 0.25), width: 1.5),
        boxShadow: glow(a.$2, blur: 12, opacity: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: a.$2.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(a.$3, color: a.$2, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.$1,
                style: TextStyle(color: a.$2, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                a.$4,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: TCC.textMuted, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// P03 — "Why TCC"
class OnboardingWhy extends StatelessWidget {
  const OnboardingWhy({super.key});
  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        Icons.wifi_off_rounded,
        'Works fully offline',
        'No data bundles needed. The model executes directly on your device CPU/GPU.'
      ),
      (
        Icons.lock_rounded,
        'Private & secure by default',
        'Your scanned documents, notes, receipts, and chat history never leave your phone.'
      ),
      (
        Icons.forum_rounded,
        'Speaks your language',
        'Switch between English, Swahili, Sheng, or Kiembu anytime in Settings.'
      ),
    ];

    return _OnboardingScaffold(
      step: 1,
      onNext: () => context.go('/onboarding/model'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Built for real campus life',
            style: TextStyle(
              color: TCC.text,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Zero cloud dependencies. Reliable utilities that work even when you are off the grid.',
            style: TextStyle(color: TCC.textMuted, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 32),
          
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: TccCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: TCC.border,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TCC.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TCC.accent.withValues(alpha: 0.25)),
                        ),
                        child: Icon(r.$1, color: TCC.accent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.$2,
                              style: const TextStyle(
                                color: TCC.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.$3,
                              style: const TextStyle(
                                color: TCC.textMuted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
