import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFFACC15); // VIDTSX Yellow
  static const Color appbarBackground = Colors.black;
  static const Color surfaceColor = Color(0xFF1E1E1E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundEnd,
      appBarTheme: const AppBarTheme(
        backgroundColor: appbarBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: surfaceColor,
        surfaceContainer: backgroundEnd,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionColor: Color(0x40FACC15),
        selectionHandleColor: primaryAccent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
