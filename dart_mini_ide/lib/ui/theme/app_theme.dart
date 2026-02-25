import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBackgroundStart = Color(0xFF050505);
  static const Color darkBackgroundEnd = Color(0xFF1a1a1a);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color primaryAccent = Color(0xFFFACC15); // VIDTSX Yellow
  static const Color toolbarButtonBg = Color(0xFFF5F5F5); // Creamy white
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackgroundStart,
    primaryColor: primaryAccent,
    colorScheme: const ColorScheme.dark(
      primary: primaryAccent,
      secondary: primaryAccent,
      surface: surfaceColor,
      error: errorRed,
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Pill
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryAccent),
      ),
      contentPadding: const EdgeInsets.all(16),
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily, // Code font mostly
  );
}
