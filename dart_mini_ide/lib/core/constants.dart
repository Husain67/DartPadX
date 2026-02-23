import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);
  static const Color accent = Color(0xFFFACC15);
  static const Color toolbarButtonBg = Color(0xFFF5F5F5);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
}

class AppConstants {
  static const String appName = 'DartMini';
  static const String appVersion = 'beta';
  static const String defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  static const String boxFiles = 'files_box';
  static const String boxSettings = 'settings_box';
  static const String boxPresets = 'presets_box';

  static const String keyActiveFileId = 'active_file_id';
  static const String keyActivePresetId = 'active_preset_id';
  static const String keyUseCustomPreset = 'use_custom_preset';

  static const String initialCode = '''void main() {
  print("Hello, DartMini!");

  // Try stdin
  // import 'dart:io';
  // String? input = stdin.readLineSync();
  // print("You typed: \$input");
}
''';
}
