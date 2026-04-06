import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (VIDTSX strict palette)
  static const Color bgColorStart = Color(0xFF050505);
  static const Color bgColorEnd = Color(0xFF1A1A1A);
  static const Color primaryYellow = Color(0xFFFACC15);
  static const Color pillBg = Color(0xFFF9F9F9);
  static const Color pillBorder = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Required for gradient container
      primaryColor: primaryYellow,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        surface: bgColorEnd,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryYellow,
        selectionColor: Color(0x66FACC15),
        selectionHandleColor: primaryYellow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pillBg,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: pillBorder, width: 1),
          ),
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [bgColorStart, bgColorEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}
