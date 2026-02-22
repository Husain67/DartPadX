import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlack = Color(0xFF050505);
  static const Color secondaryBlack = Color(0xFF1A1A1A);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color toolbarButtonColor = Color(0xFFF5F5F5); // White/Cream
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryBlack, // Will be overridden by gradient container
    primaryColor: primaryBlack,
    colorScheme: const ColorScheme.dark(
      primary: accentYellow,
      secondary: accentYellow,
      surface: secondaryBlack,
      error: errorRed,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Pure black
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentYellow,
      foregroundColor: Colors.black,
    ),
    // dialogTheme: DialogTheme(
    //   backgroundColor: secondaryBlack,
    //   surfaceTintColor: Colors.transparent,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //     side: BorderSide(color: Colors.white10, width: 1),
    //   ),
    // ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: secondaryBlack,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBlack, secondaryBlack],
  );
}
