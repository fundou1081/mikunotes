import 'package:flutter/material.dart';

class AppTheme {
  // Miku 主题色: cyan 主调 + pink 点缀
  static const _seedColor = Color(0xFF39C5BB); // Miku cyan

  static ColorScheme _scheme(Brightness b) =>
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: b);

  static ThemeData get light {
    final cs = _scheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs.copyWith(
        secondary: const Color(0xFFFF8FB1), // Miku pink
      ),
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: cs.surfaceContainerLow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
      ),
    );
  }

  static ThemeData get dark {
    final cs = _scheme(Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs.copyWith(
        secondary: const Color(0xFFFF8FB1), // Miku pink
      ),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: cs.surfaceContainerLow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
      ),
    );
  }
}
