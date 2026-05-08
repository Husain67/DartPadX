import 'dart:convert';

class Constants {
  // Default API Key (obfuscated)
  static String get oneCompilerApiKey => String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));

  static const String oneCompilerUrl = "https://onecompiler-apis.p.rapidapi.com/api/v1/run";

  // Default code for new dart files
  static const String defaultDartCode = """
import 'dart:io';

void main() {
  print('Hello from DartMini IDE! 🚀');

  // Example of reading from stdin
  // print('Enter something:');
  // String? input = stdin.readLineSync();
  // print('You entered: \$input');
}
""";

  static const String testConnectionCode = """
void main() {
  print('Hello from custom API');
}
""";
}
