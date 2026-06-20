import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFFFACC15); // VIDTSX golden yellow
  static const Color backgroundBlack = Color(0xFF050505); // Deep black
  static const Color surfaceBlack = Color(0xFF1A1A1A); // Slightly lighter black
  static const Color appbarBlack = Color(0xFF000000); // Pure black
  static const Color textWhite = Color(0xFFF5F5F5); // Off-white for text
  static const Color textMuted = Color(0xFFA0A0A0); // Muted gray for text
  static const Color buttonCream = Color(0xFFFDFDFD); // White/cream for buttons

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        surface: surfaceBlack,
        onSurface: textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appbarBlack,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryAccent),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: Color(0x66FACC15),
        selectionHandleColor: primaryAccent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: appbarBlack,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: appbarBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryAccent,
        unselectedLabelColor: textMuted,
        indicatorColor: primaryAccent,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }
}
