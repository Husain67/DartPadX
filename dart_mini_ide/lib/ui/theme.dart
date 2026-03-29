import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppConstants.accentColor,
      scaffoldBackgroundColor: AppConstants.bgColorStart, // Will be overridden by gradient container
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.accentColor,
        secondary: AppConstants.accentColor,
        surface: AppConstants.bgColorEnd,
        error: AppConstants.errorColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.accentColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.bgColorStart.withValues(alpha: 255 * 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 255 * 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 255 * 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.accentColor),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 255 * 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 255 * 0.5)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 255 * 0.1),
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppConstants.bgColorEnd,
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: AppConstants.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppConstants.bgColorEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static BoxDecoration get scaffoldGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.bgColorStart,
            AppConstants.bgColorEnd,
          ],
        ),
      );
}
