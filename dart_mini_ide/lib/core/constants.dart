import 'package:flutter/material.dart';

class AppColors {
  // Deep black gradient background (#050505 -> #1a1a1a)
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);

  // Bright yellow accent (#FACC15)
  static const Color accent = Color(0xFFFACC15);

  // Pure black
  static const Color pureBlack = Color(0xFF000000);

  // White/cream for buttons
  static const Color buttonBackground = Color(0xFFF9F9F9);

  // Thin border for buttons
  static const Color buttonBorder = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);

  // Console output colors
  static const Color outputGreen = Color(0xFF4ADE80);
  static const Color outputRed = Color(0xFFF87171);
}

class AppConstants {
  static const double mobileMaxWidth = 480.0;
  static const double mobileMinWidth = 320.0;
  static const double toolbarButtonSize = 48.0;

  static const String appName = 'DartMini';
  static const String appVersion = 'beta';

  static const String defaultFileName = 'main.dart';
  static const String defaultCode = '''void main() {
  print('Hello, DartMini IDE!');
}''';
}
