import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackgroundTop = Color(0xFF050505);
  static const Color darkBackgroundBottom = Color(0xFF1a1a1a);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color toolbarButtonBg = Color(0xFFF9F9F9);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentYellow,
      scaffoldBackgroundColor: Colors.transparent, // Handled by gradient container
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkBackgroundBottom,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: accentYellow,
        surface: darkBackgroundBottom,
        error: errorRed,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentYellow,
        selectionColor: Color(0x66FACC15),
        selectionHandleColor: accentYellow,
      ),
    );
  }
}
