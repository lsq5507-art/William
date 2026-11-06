import 'package:flutter/material.dart';

/// Internal ops tokens (D-21) — not C-end Premium.
class OpsTheme {
  OpsTheme._();

  static const Color bg = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1B2430);
  static const Color navy = Color(0xFF243B53);
  static const Color muted = Color(0xFF5C6B7A);
  static const Color line = Color(0xFFD9DEE5);
  static const Color chip = Color(0xFFEEF1F5);
  static const Color ok = Color(0xFF1F7A4D);
  static const Color warn = Color(0xFFB58105);
  static const Color deny = Color(0xFFB42318);
  static const Color railFormal = Color(0xFF243B53);
  static const Color railSim = Color(0xFF6B7280);

  static ThemeData material() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        brightness: Brightness.light,
        primary: navy,
        surface: surface,
      ),
      dividerColor: line,
      fontFamily: null,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: line),
        ),
      ),
    );
  }
}
