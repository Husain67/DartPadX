

class AppConstants {
  static const String appName = 'DartMini';
  static const String version = 'beta';

  static const String defaultFileName = 'main.dart';
  static const String defaultFileContent = '''
import 'dart:io';

void main() {
  print('Welcome to DartMini IDE!');

  // Example of using standard input
  print('Please enter your name:');
  String? name = stdin.readLineSync();
  if (name != null && name.isNotEmpty) {
    print('Hello, \$name!');
  } else {
    print('Hello, Guest!');
  }
}
''';

  static const String oneCompilerEndpoint = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String oneCompilerDefaultKey = String.fromEnvironment('API_KEY');
}
