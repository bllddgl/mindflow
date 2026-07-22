import 'package:flutter/material.dart';

/// The three reading themes MindFlow supports. Sepia is a full
/// [ColorScheme], not a color filter over light -- so contrast stays
/// correct and every Material control renders consistently.
enum AppThemeMode { light, dark, sepia }

class AppTheme {
  AppTheme._();

  static const Color _sepiaBackground = Color(0xFFF4ECD8);
  static const Color _sepiaSurface = Color(0xFFEFE3C8);
  static const Color _sepiaOnSurface = Color(0xFF4B3B21);
  static const Color _sepiaPrimary = Color(0xFF8B5E34);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E5AAC)),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5AAC),
          brightness: Brightness.dark,
        ),
      );

  static ThemeData sepia() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _sepiaPrimary,
      brightness: Brightness.light,
      background: _sepiaBackground,
      surface: _sepiaSurface,
      onBackground: _sepiaOnSurface,
      onSurface: _sepiaOnSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _sepiaBackground,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: _sepiaOnSurface,
            displayColor: _sepiaOnSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: _sepiaBackground,
        foregroundColor: _sepiaOnSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light();
      case AppThemeMode.dark:
        return dark();
      case AppThemeMode.sepia:
        return sepia();
    }
  }
}
