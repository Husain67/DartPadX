import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackgroundStart = Color(0xFF050505);
  static const Color darkBackgroundEnd = Color(0xFF1a1a1a);
  static const Color pureBlack = Color(0xFF000000);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color textCream = Color(0xFFF5F5DC); // Used for toolbars

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackgroundStart,
      primaryColor: pureBlack,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        surface: pureBlack,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentYellow,
        unselectedLabelColor: Colors.grey,
        indicatorColor: accentYellow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkBackgroundEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      useMaterial3: true,
    );
  }
}
