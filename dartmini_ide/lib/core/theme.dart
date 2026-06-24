import 'package:flutter/material.dart';

class DartMiniTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFFACC15); // Bright yellow/golden
  static const Color appBarBlack = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFF222222);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundStart,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        contentTextStyle: const TextStyle(fontSize: 16, color: textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: Color(0x66FACC15),
        selectionHandleColor: primaryAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
    );
  }

  static BoxDecoration get backgroundGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [backgroundStart, backgroundEnd],
    ),
  );
}
