import 'dart:convert';
class AppConstants {
  static final String defaultOneCompilerKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));
  static const String defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';

  static const String initialMainDartContent = '''
import 'dart:io';
import 'dart:convert';

void main() {
  print('Hello from DartMini IDE!');

  // Example of reading stdin
  // var name = stdin.readLineSync();
  // print('Hello, \$name!');
}
''';
}
