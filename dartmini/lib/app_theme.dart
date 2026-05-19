import 'package:flutter/material.dart';

class AppTheme {
  // Colors (VIDTSX style)
  static const Color primaryYellow = Color(0xFFFACC15);
  static const Color backgroundDeepBlack = Color(0xFF050505);
  static const Color backgroundGradientEnd = Color(0xFF1A1A1A);
  static const Color appBarBlack = Colors.black;
  static const Color textLight = Colors.white;
  static const Color toolbarButtonBg = Color(0xFFF5F5F5);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryYellow,
      scaffoldBackgroundColor: backgroundDeepBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        surface: backgroundDeepBlack,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundGradientEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryYellow.withValues(alpha: 0.3)),
        ),
        titleTextStyle: const TextStyle(color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: backgroundGradientEnd,
        contentTextStyle: TextStyle(color: textLight),
      ),
    );
  }

  // Common background gradient for screens
  static BoxDecoration get backgroundGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        backgroundDeepBlack,
        backgroundGradientEnd,
      ],
    ),
  );
}
