import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

class Constants {
  static const String rapidApiKey = String.fromEnvironment('RAPID_API_KEY');

  static const String defaultDartCode = '''import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');
  stdout.write('Please enter your name: ');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}
''';

  static List<CompilerPreset> get defaultPresets {
    final uuid = const Uuid();
    return [
      CompilerPreset(
        id: uuid.v4(),
        name: 'OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: rapidApiKey,
        headers: {
          'content-type': 'application/json',
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'x-rapidapi-key': rapidApiKey,
        },
        queryParams: {},
        bodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "main.dart",
      "content": {code}
    }
  ]
}''',
        resultPaths: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'exception',
          'executionTime': 'executionTime',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {
          'content-type': 'application/json'
        },
        queryParams: {},
        bodyTemplate: '''{
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET",
  "script": {code},
  "stdin": "{stdin}",
  "language": "dart",
  "versionIndex": "0"
}''',
        resultPaths: {
          'stdout': 'output',
          'stderr': '',
          'error': 'error',
          'executionTime': 'cpuTime',
          'memory': 'memory'
        },
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Piston',
        url: 'https://emacs.piston.rs/api/v2/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {
          'content-type': 'application/json'
        },
        queryParams: {},
        bodyTemplate: '''{
  "language": "dart",
  "version": "3.3.3",
  "files": [
    {
      "name": "main.dart",
      "content": {code}
    }
  ],
  "stdin": "{stdin}"
}''',
        resultPaths: {
          'stdout': 'run.stdout',
          'stderr': 'run.stderr',
          'error': 'compile.stderr',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'CodeX',
        url: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {
          'content-type': 'application/x-www-form-urlencoded'
        },
        queryParams: {},
        bodyTemplate: 'code={code}&language=dart&input={stdin}',
        resultPaths: {
          'stdout': 'output',
          'stderr': 'error',
          'error': 'error',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Replit',
        url: '',
        method: 'POST',
        authType: 'Bearer Token',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        resultPaths: {
          'stdout': '',
          'stderr': '',
          'error': '',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'HackerEarth',
        url: '',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        resultPaths: {
          'stdout': '',
          'stderr': '',
          'error': '',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Blank',
        url: '',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        resultPaths: {
          'stdout': '',
          'stderr': '',
          'error': '',
          'executionTime': '',
          'memory': ''
        },
      ),
    ];
  }
}