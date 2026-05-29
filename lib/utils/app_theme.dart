import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFFFACC15);
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color appBarColor = Colors.black;
  static const Color textColor = Colors.white;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundStart,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: Color(0x66FACC15),
        selectionHandleColor: primaryAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
  }

  static BoxDecoration get backgroundGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundStart, backgroundEnd],
      ),
    );
  }
}
