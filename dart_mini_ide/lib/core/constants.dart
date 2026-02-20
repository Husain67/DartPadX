import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'DartMini';
  static const String appVersion = 'beta';

  static const Color primaryColor = Color(0xFFFACC15); // Bright yellow
  static const Color backgroundColorStart = Color(0xFF050505);
  static const Color backgroundColorEnd = Color(0xFF1A1A1A);
  static const Color toolbarButtonColor = Color(0xFFF5F5F5); // White/Cream
  static const Color toolbarButtonBorderColor = Color(0xFFE0E0E0);

  static const Color surfaceColor = Color(0xFF1E1E1E);

  // Hive Boxes
  static const String fileBoxName = 'code_files';
  static const String settingsBoxName = 'settings';
  static const String presetBoxName = 'compiler_presets';

  // Default Code
  static const String defaultCode = """void main() {
  print('Hello, DartMini!');

  // Example: Async
  Future.delayed(Duration(seconds: 1), () {
    print('Async hello after 1 second');
  });
}
""";
}
