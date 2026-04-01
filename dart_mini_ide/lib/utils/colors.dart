import 'package:flutter/material.dart';

class AppColors {
  // Deep black/dark gradient background (#050505 -> #1a1a1a)
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);

  // Top AppBar: pure black
  static const Color appBarBackground = Color(0xFF000000);

  // Primary accent: bright yellow/golden #FACC15
  static const Color accentYellow = Color(0xFFFACC15);

  // All toolbar buttons: white/cream background with thin border
  static const Color toolbarButtonBg = Color(0xFFF9F9F9);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color toolbarButtonText = Color(0xFF1A1A1A);

  // Editor colors
  static const Color editorBackground = Color(0xFF0D0D0D);
  static const Color editorLineNumber = Color(0xFF666666);
  static const Color editorText = Color(0xFFE0E0E0);

  // Output sheet
  static const Color outputSheetBackground = Color(0xFF151515);
  static const Color outputStdout = Color(0xFF4ADE80); // Green
  static const Color outputStderr = Color(0xFFEF4444); // Red
  static const Color outputText = Color(0xFFE0E0E0);

  // Dialogs
  static const Color dialogBackground = Color(0xFF1E1E1E);

  // Tab
  static const Color tabActive = Color(0xFF2D2D2D);
  static const Color tabInactive = Color(0xFF151515);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundStart,
      primaryColor: accentYellow,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: accentYellow,
        surface: appBarBackground,
        error: outputStderr,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: accentYellow),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: outputSheetBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}