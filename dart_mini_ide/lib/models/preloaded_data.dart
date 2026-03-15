import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class PreloadedData {
  static const uuid = Uuid();

  static final String defaultCode = '''
import 'dart:io';

void main() {
  print('Welcome to DartMini IDE!');
  print('Environment ready.');

  // Read from stdin example:
  // String? name = stdin.readLineSync();
  // print('Hello \$name!');
}
''';

  static final List<CompilerPreset> presets = [
    CompilerPreset(
      id: 'default_onecompiler',
      platformName: 'OneCompiler (Default)',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      queryParams: {},
      requestBodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "main.dart",
      "content": {code}
    }
  ]
}''',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: 'memory',
    ),
    CompilerPreset(
      id: uuid.v4(),
      platformName: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '''{
  "script": {code},
  "language": "dart",
  "versionIndex": "0",
  "stdin": "{stdin}",
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET"
}''',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
    ),
    CompilerPreset(
      id: uuid.v4(),
      platformName: 'Piston',
      endpointUrl: 'https://emkc.org/api/v2/piston/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '''{
  "language": "dart",
  "version": "*",
  "files": [
    {
      "content": {code}
    }
  ],
  "stdin": "{stdin}"
}''',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'compile.stderr',
      executionTimePath: '',
      memoryPath: '',
    ),
    CompilerPreset(
      id: uuid.v4(),
      platformName: 'Blank Custom API',
      endpointUrl: 'https://api.example.com/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '''{
  "code": {code},
  "lang": "dart"
}''',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'message',
      executionTimePath: 'time',
      memoryPath: 'memory',
    ),
  ];
}
