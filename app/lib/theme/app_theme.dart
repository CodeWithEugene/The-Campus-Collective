import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

/// Dark-only Material 3 theme for TCC.
class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: TCC.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: TCC.primary,
      secondary: TCC.accent,
      surface: TCC.surface,
      error: TCC.danger,
      onPrimary: Colors.white,
      onSurface: TCC.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: TCC.bg,
      colorScheme: scheme,
      canvasColor: TCC.bg,
      splashColor: TCC.primary.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: TCC.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: TCC.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: TCC.text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: TCC.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TCC.radius),
          side: const BorderSide(color: TCC.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: TCC.border, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TCC.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: TCC.surface2,
          disabledForegroundColor: TCC.textDisabled,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TCC.radius)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TCC.text,
          side: const BorderSide(color: TCC.border),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TCC.radius)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: TCC.accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TCC.surface2,
        hintStyle: const TextStyle(color: TCC.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TCC.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TCC.radius),
          borderSide: const BorderSide(color: TCC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TCC.radius),
          borderSide: const BorderSide(color: TCC.accent, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TCC.surface2,
        side: const BorderSide(color: TCC.border),
        labelStyle: const TextStyle(color: TCC.text, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TCC.surface2,
        contentTextStyle: const TextStyle(color: TCC.text, fontWeight: FontWeight.w600),
        actionTextColor: TCC.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TCC.radius)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TCC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TCC.radiusLg)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TCC.accent,
        linearTrackColor: TCC.surface2,
        circularTrackColor: TCC.surface2,
      ),
      iconTheme: const IconThemeData(color: TCC.text),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    TextStyle s(double size, FontWeight w, {Color c = TCC.text, double h = 1.4}) =>
        TextStyle(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: 0.1);
    return base
        .copyWith(
          displaySmall: s(30, FontWeight.w800, h: 1.15),
          headlineMedium: s(24, FontWeight.w700, h: 1.2),
          titleLarge: s(20, FontWeight.w700),
          titleMedium: s(16, FontWeight.w600),
          bodyLarge: s(16, FontWeight.w400, h: 1.5),
          bodyMedium: s(14, FontWeight.w400, c: TCC.textMuted, h: 1.5),
          labelLarge: s(14, FontWeight.w600),
          labelSmall: s(12, FontWeight.w500, c: TCC.textMuted),
        )
        .apply(bodyColor: TCC.text, displayColor: TCC.text);
  }
}
