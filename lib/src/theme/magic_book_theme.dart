import 'package:flutter/material.dart';

class MagicBookColors {
  static const purple = Color(0xFF7654F5);
  static const deepPurple = Color(0xFF241A52);
  static const lavender = Color(0xFFF7F3FF);
  static const yellow = Color(0xFFFFD84D);
  static const pink = Color(0xFFFF7FA5);
  static const mint = Color(0xFF59D2A6);
  static const sky = Color(0xFF73C7F4);
  static const ink = Color(0xFF171336);
  static const line = Color(0xFFE6E0F5);
}

class MagicBookTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: MagicBookColors.purple,
      primary: MagicBookColors.purple,
      secondary: MagicBookColors.yellow,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MagicBookColors.lavender,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: MagicBookColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: MagicBookColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: MagicBookColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: MagicBookColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: MagicBookColors.ink,
          height: 1.25,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: MagicBookColors.ink,
          height: 1.3,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: MagicBookColors.ink,
        titleTextStyle: TextStyle(
          color: MagicBookColors.purple,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: MagicBookColors.lavender,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? MagicBookColors.purple
                : Colors.black54,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? MagicBookColors.purple
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}
