import 'package:flutter/material.dart';

class AppTheme {
  // Deep black to dark gray gradient
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);

  static const Color appBarColor = Colors.black;
  static const Color primaryAccent = Color(0xFFFACC15); // VIDTSX Yellow
  static const Color toolbarButtonBg = Color(0xFFF4F4F5); // White/cream

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryAccent,
        surface: backgroundEnd,
        surfaceContainer: backgroundStart,
      ),
      scaffoldBackgroundColor: Colors.transparent, // We'll use a Container with BoxGradient in the UI
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundStart, backgroundEnd],
      ),
    );
  }
}
