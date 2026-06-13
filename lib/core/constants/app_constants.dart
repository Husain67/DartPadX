class AppConstants {
  static const String appName = 'DartMini IDE';
  static const String version = 'beta';

  // Hive Box Names
  static const String settingsBox = 'settingsBox';
  static const String filesBox = 'filesBox';
  static const String presetsBox = 'presetsBox';

  // Settings Keys
  static const String activeFileIdKey = 'activeFileId';
  static const String activePresetIdKey = 'activePresetId';

  // API Default
  static const String defaultOneCompilerKey = String.fromEnvironment(
    'ONECOMPILER_API_KEY',
    defaultValue: ''
  );

  static const String defaultCode = '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');

  // Example of reading input
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Welcome to mobile coding, \$name!');
}
''';
}
