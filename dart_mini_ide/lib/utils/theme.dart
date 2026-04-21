import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color bgDarkStart = Color(0xFF050505);
  static const Color bgDarkEnd = Color(0xFF1A1A1A);
  static const Color toolbarItemBg = Color(0xFFF9F9F9);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        surface: bgDarkEnd,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgDarkEnd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
