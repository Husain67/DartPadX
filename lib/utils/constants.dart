class AppConstants {
  static const String appName = 'DartMini';
  static const String appVersion = 'beta';

  static const String defaultFileName = 'main.dart';

  static const String defaultDartCode = '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');
  print('Enter your name: ');

  // Read input from stdin
  String? name = stdin.readLineSync();
  print('Welcome, ${name ?? "Guest"}!');
}
''';

  static const String defaultOneCompilerKey = String.fromEnvironment('ONE_COMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

  // Hive Box Names
  static const String filesBox = 'files_box_v1';
  static const String settingsBox = 'settings_box_v1';
  static const String presetsBox = 'presets_box_v1';
}
