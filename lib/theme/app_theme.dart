import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);
  static const Color primaryAccent = Color(0xFFFACC15);
  static const Color toolbarButtonBg = Color(0xFFE8E8E8); // off-white/cream

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Allow gradient from container
      primaryColor: primaryAccent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: Color(0xFF1a1a1a),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: Color(0x66FACC15),
        selectionHandleColor: primaryAccent,
      ),
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
