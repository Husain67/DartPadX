import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF050505);
  static const Color lighterBackground = Color(0xFF1a1a1a);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color whiteCream = Color(0xFFF9F9F9);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color surfaceColor = Color(0xFF222222);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: accentYellow,
    colorScheme: const ColorScheme.dark(
      primary: accentYellow,
      surface: surfaceColor,

    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: lighterBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );

  static final BoxDecoration backgroundGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [darkBackground, lighterBackground],
    ),
  );
}
