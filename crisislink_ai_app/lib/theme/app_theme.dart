import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF050505);
  static const Color panel = Color(0xFF14141B);
  static const Color panelBorder = Color(0xFF3A3442);
  static const Color accentRed = Color(0xFFFF1010);
  static const Color accentRedDark = Color(0xFFC6000A);
  static const Color textPrimary = Color(0xFFF6F2F4);
  static const Color textMuted = Color(0xFF7A7582);
  static const Color success = Color(0xFF00D26A);
  static const Color warning = Color(0xFFFFA63D);

  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        surface: panel,
        primary: accentRed,
        secondary: success,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B1B22),
        hintStyle: const TextStyle(color: Color(0xFF8E8894)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF413B46)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 1.2),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
