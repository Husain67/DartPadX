import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppConstants.primaryColor,
    scaffoldBackgroundColor: AppConstants.backgroundColorStart,
    colorScheme: const ColorScheme.dark(
      primary: AppConstants.primaryColor,
      surface: AppConstants.backgroundColorEnd,
      onSurface: Colors.white,
      secondary: AppConstants.primaryColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    // dialogTheme: DialogTheme(
    //   backgroundColor: AppConstants.surfaceColor,
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    // ),
  );
}
