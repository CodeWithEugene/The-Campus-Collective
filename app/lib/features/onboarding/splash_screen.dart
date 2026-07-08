import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_state.dart';
import '../../theme/tokens.dart';

/// P01 — static logo splash + boot routing.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _c.forward();
    _boot();
  }

  Future<void> _boot() async {
    // Elegant, short 1.6s delay for splash scale transition
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final flags = ref.read(appFlagsProvider);
    if (!flags.onboarded) {
      context.go('/onboarding/1');
    } else if (!flags.modelReady) {
      context.go('/onboarding/model');
    } else {
      context.go('/chat');
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TCC.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: _c,
                child: SvgPicture.asset(TCC.logoStatic, width: 140, height: 140),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: const Interval(0.5, 1)),
              child: const Text(
                'T C C',
                style: TextStyle(
                  color: TCC.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
