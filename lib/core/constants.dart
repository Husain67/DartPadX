import 'dart:convert';
import '../models/compiler_preset.dart';

class AppConstants {
  static const String hiveFileBox = 'codeFiles';
  static const String hiveSettingsBox = 'settingsBox';
  static const String hivePresetBox = 'compilerPresetsBox';

  static String get defaultOneCompilerKey {
    return String.fromCharCodes(base64Decode(
        'b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));
  }

  static const String defaultDartCode = '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');

  // Example of reading standard input
  // String? input = stdin.readLineSync();
  // print('Received: \$input');
}
''';

  static List<CompilerPreset> get preloadedPresets => [
    CompilerPreset(
      id: 'onecompiler-default',
      name: 'OneCompiler (Dart)',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authKey: 'x-rapidapi-key',
      authValue: defaultOneCompilerKey,
      headers: {
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      bodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ]
}''',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
    ),
    CompilerPreset(
      id: 'jdoodle-default',
      name: 'JDoodle (Dart)',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      bodyTemplate: '''{
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET",
  "script": "{code}",
  "stdin": "{stdin}",
  "language": "dart",
  "versionIndex": "0"
}''',
      stdoutPath: 'output',
      stderrPath: '',
      errorPath: 'error',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
    ),
    CompilerPreset(
      id: 'piston-default',
      name: 'Piston (Dart)',
      endpointUrl: 'https://emkc.org/api/v2/piston/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      bodyTemplate: '''{
  "language": "dart",
  "version": "*",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ],
  "stdin": "{stdin}"
}''',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'message',
      executionTimePath: '',
      memoryPath: '',
    ),
    CompilerPreset(
      id: 'replit-default',
      name: 'Replit (Dart)',
      endpointUrl: 'https://replit.com/api/v1/repls/...',
      httpMethod: 'POST',
      authType: 'Bearer Token',
      authValue: 'YOUR_REPLIT_TOKEN',
      bodyTemplate: '''{
  "code": "{code}"
}''',
    ),
    CompilerPreset(
      id: 'codex-default',
      name: 'CodeX (Dart)',
      endpointUrl: 'https://api.codex.jaagrav.in',
      httpMethod: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      bodyTemplate: 'code={code}&language=dart&input={stdin}',
      stdoutPath: 'output',
      errorPath: 'error',
    ),
    CompilerPreset(
      id: 'hackerearth-default',
      name: 'HackerEarth (Dart)',
      endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authKey: 'client-secret',
      authValue: 'YOUR_HACKEREARTH_SECRET',
      headers: {
        'Content-Type': 'application/json',
      },
      bodyTemplate: '''{
  "lang": "DART",
  "source": "{code}",
  "input": "{stdin}",
  "memory_limit": 262144,
  "time_limit": 5
}''',
    ),
    CompilerPreset(
      id: 'blank-default',
      name: 'Blank Preset',
      endpointUrl: '',
      bodyTemplate: '{code}',
    ),
  ];
}
