import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primary = Color(0xFF00E5C7);
  static const Color _bgDark = Color(0xFF0A0E1A);
  static const Color _surfaceDark = Color(0xFF131826);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final bool dark = b == Brightness.dark;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: b,
      primary: _primary,
      surface: dark ? _surfaceDark : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? _bgDark : const Color(0xFFF6F8FB),
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1.2),
        headlineMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? _surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
