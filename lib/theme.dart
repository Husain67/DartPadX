import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);
  static const Color primaryAccent = Color(0xFFFACC15); // Bright yellow/golden
  static const Color appBarColor = Colors.black;
  static const Color toolbarButtonBg = Color(0xFFE8E8E8); // White/cream
  static const Color textMain = Colors.white;
  static const Color textSecondary = Colors.grey;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Handled by Container with gradient
      primaryColor: primaryAccent,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: appBarColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: toolbarButtonBg,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          minimumSize: const Size(48, 48),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryAccent,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryAccent,
        dividerColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
