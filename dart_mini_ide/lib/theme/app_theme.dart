import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color primaryYellow = Color(0xFFFACC15);
  static const Color appbarBlack = Color(0xFF000000);
  static const Color toolbarButtonBg = Color(0xFFF5F5F5); // cream/white
  static const Color textWhite = Colors.white;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundStart, // will be overridden by gradient container
      appBarTheme: const AppBarTheme(
        backgroundColor: appbarBlack,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textWhite),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: primaryYellow,
        surface: backgroundEnd,
        error: Colors.redAccent,
        onPrimary: Colors.black,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}
