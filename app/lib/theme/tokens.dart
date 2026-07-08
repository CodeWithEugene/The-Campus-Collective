import 'package:flutter/material.dart';

/// The Campus Collective design tokens (project.md §16.1).
/// Dark-only, pure-black AMOLED. Colors derive from the logo pinwheel.
class TCC {
  TCC._();

  // Core palette
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0F);
  static const Color surface2 = Color(0xFF131316);
  static const Color border = Color(0xFF1F1F24);

  static const Color primary = Color(0xFF6706E5); // logo purple
  static const Color accent = Color(0xFF1AD8C9); // logo teal

  static const Color text = Color(0xFFF5F5F7);
  static const Color textMuted = Color(0xFFA0A0A8);
  static const Color textDisabled = Color(0xFF5A5A62);

  static const Color danger = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFF0A500);
  static const Color success = accent;

  // Agent identity tints (project.md §16.1)
  static const Color somo = Color(0xFF6706E5);
  static const Color karani = Color(0xFFF0A500);
  static const Color hustle = Color(0xFF2ECC71);
  static const Color ratiba = Color(0xFF1AD8C9);

  // Geometry
  static const double radius = 18;
  static const double radiusSm = 12;
  static const double radiusLg = 28;
  static const EdgeInsets pagePad = EdgeInsets.symmetric(horizontal: 20);
  static const double gap = 16;

  // Brand assets
  static const String logoStatic = 'assets/brand/logo_static.svg';
  static const String logoIcon = 'assets/brand/logo_icon.svg';
  static const String logoAnimated = 'assets/brand/logo_animated.gif';

  static Color agentColor(String agent) {
    switch (agent.toLowerCase()) {
      case 'somo':
        return somo;
      case 'karani':
        return karani;
      case 'hustle':
        return hustle;
      case 'ratiba':
        return ratiba;
      default:
        return textMuted;
    }
  }
}

/// Soft glow used on hero cards & CTAs for a premium feel.
List<BoxShadow> glow(Color c, {double blur = 24, double opacity = 0.35}) => [
  BoxShadow(color: c.withValues(alpha: opacity), blurRadius: blur, spreadRadius: -6),
];
