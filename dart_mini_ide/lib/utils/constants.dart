class Constants {
  static const String defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  static const String initialMainDartCode = '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');

  // Example of reading input
  print('Enter your name:');
  String? name = stdin.readLineSync();
  if (name != null && name.isNotEmpty) {
    print('Welcome, \$name!');
  }
}
''';
}
