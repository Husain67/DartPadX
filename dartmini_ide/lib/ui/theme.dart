import 'package:flutter/material.dart';

class AppTheme {
  // Deep black/dark gradient background (#050505 -> #1a1a1a)
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color appBarColor = Colors.black;
  static const Color primaryAccent = Color(0xFFFACC15); // bright yellow/golden
  static const Color buttonBackground = Color(0xFFF5F5DC); // cream/white

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: Colors.transparent, // Handled by Container gradient
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: primaryAccent,
        labelColor: primaryAccent,
        unselectedLabelColor: Colors.white54,
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
