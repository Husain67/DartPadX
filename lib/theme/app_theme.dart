import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);
  static const Color appbarBlack = Colors.black;
  static const Color primaryYellow = Color(0xFFFACC15);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: primaryYellow,
      surface: surfaceColor,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: appbarBlack,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [backgroundStart, backgroundEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static ButtonStyle get toolbarButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFAFAFA),
      foregroundColor: Colors.black87,
      elevation: 0,
      fixedSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.black12, width: 1),
      ),
    );
  }
}
