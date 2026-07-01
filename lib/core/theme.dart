import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFFACC15); // Bright yellow
  static const Color appBarColor = Colors.black;
  static const Color toolbarButtonColor = Color(0xFFF5F5F5); // Cream/White
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color textColor = Colors.white;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: Colors.transparent, // Uses gradient wrapper
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: backgroundEnd,
        error: Colors.redAccent,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textColor,
      ),
      useMaterial3: true,
      tabBarTheme: TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: accentColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Helper widget to wrap screens in the deep dark gradient
  static Widget gradientBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundStart, backgroundEnd],
        ),
      ),
      child: child,
    );
  }
}
