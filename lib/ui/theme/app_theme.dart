import 'package:flutter/material.dart';

class AppTheme {
  // 蓝白主题
  static const _seedColor = Color(0xFF1976D2); // Material Blue 700

  static ColorScheme _scheme(Brightness b) =>
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: b);

  static ThemeData get light {
    final cs = _scheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs.copyWith(
        
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
