import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFFFACC15);
  static const Color bgDarkStart = Color(0xFF050505);
  static const Color bgDarkEnd = Color(0xFF1A1A1A);
  static const Color pureBlack = Colors.black;
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color textColor = Colors.white;
  static const Color textLightColor = Color(0xFFAAAAAA);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: pureBlack,
      colorScheme: ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        foregroundColor: textColor,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryAccent,
        unselectedLabelColor: textLightColor,
        indicatorColor: primaryAccent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: Color(0x40FACC15),
        selectionHandleColor: primaryAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: pureBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  static BoxDecoration get bgGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgDarkStart, bgDarkEnd],
      ),
    );
  }
}
