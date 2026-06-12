class Constants {
  static const String appName = 'DartMini IDE';
  static const String defaultFileName = 'main.dart';
  static const String defaultFileContent = '''
import 'dart:io';

void main() {
  print('Welcome to DartMini IDE!');

  // Read from standard input (if provided)
  print('Enter your name:');
  String? name = stdin.readLineSync();
  if (name != null && name.isNotEmpty) {
    print('Hello, \$name!');
  }
}
''';

  static const String oneCompilerApiKey = String.fromEnvironment(
    'ONECOMPILER_API_KEY',
    defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
  );

  static const String boxFiles = 'files_box';
  static const String boxSettings = 'settings_box';
  static const String boxPresets = 'presets_box';

  static const String defaultPresetId = 'default_onecompiler';
}
