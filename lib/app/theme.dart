import 'package:flutter/material.dart';

/// Defines the application Material 3 themes for light and dark modes.
class AppTheme {
  const AppTheme._();

  // Primary brand seed color: a welcoming, calm slate/indigo.
  static const Color _seedColor = Color(0xFF2E5B88);

  /// Material 3 Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  /// Material 3 Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
