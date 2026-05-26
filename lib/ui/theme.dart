import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF050505);
  static const Color darkSurface = Color(0xFF1a1a1a);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color textLight = Color(0xFFF3F4F6);
  static const Color textDim = Color(0xFF9CA3AF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentYellow,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        surface: darkSurface,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: accentYellow,
        labelColor: accentYellow,
        unselectedLabelColor: textDim,
      ),
    );
  }
}
