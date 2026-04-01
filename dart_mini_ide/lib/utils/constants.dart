import '../models/compiler_preset.dart';

class AppConstants {
  static const String appName = 'DartMini';
  static const String version = 'beta';

  static const String fileBoxName = 'dart_mini_ide_files';
  static const String settingsBoxName = 'dart_mini_ide_settings';
  static const String presetBoxName = 'dart_mini_ide_presets';

  static const String activeFileIdKey = 'active_file_id';
  static const String activePresetIdKey = 'active_preset_id';

  // Default OneCompiler API configuration
  static const String oneCompilerApiKey =
      'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  // Examples gallery
  static const Map<String, String> examples = {
    'Hello World': '''void main() {
  print('Hello, World!');
}''',
    'Input/Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  // Reading from stdin
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
    'List': '''void main() {
  List<int> numbers = [1, 2, 3, 4, 5];

  // Print each number
  for (int number in numbers) {
    print('Number: \$number');
  }
}''',
    'Class': '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void sayHello() {
    print('Hello, my name is \$name and I am \$age years old.');
  }
}

void main() {
  var person = Person('Dart', 10);
  person.sayHello();
}''',
    'Async': '''Future<void> main() async {
  print('Fetching data...');
  var data = await fetchData();
  print('Data fetched: \$data');
}

Future<String> fetchData() async {
  // Simulate a network request
  await Future.delayed(Duration(seconds: 2));
  return 'Dart is awesome!';
}''',
  };

  // Pre-loaded custom compiler presets
  static final List<CompilerPreset> defaultPresets = [
    CompilerPreset(
      id: 'preset_onecompiler',
      name: 'OneCompiler (Default)',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: oneCompilerApiKey,
      headers: {
        'x-rapidapi-key': oneCompilerApiKey,
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
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
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '', // OneCompiler does not seem to return memory out of the box
      isDefault: true,
    ),
    CompilerPreset(
      id: 'preset_jdoodle',
      name: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None', // JDoodle auth goes in body
      authValue: '',
      headers: {
        'Content-Type': 'application/json',
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
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
      isDefault: false,
    ),
    CompilerPreset(
      id: 'preset_piston',
      name: 'Piston',
      endpointUrl: 'https://emkc.org/api/v2/piston/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      queryParams: {},
      bodyTemplate: '''{
  "language": "dart",
  "version": "*",
  "files": [
    {
      "name": "main.dart",
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
      isDefault: false,
    ),
    CompilerPreset(
      id: 'preset_codex',
      name: 'CodeX',
      endpointUrl: 'https://api.codex.jaagrav.in',
      httpMethod: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      queryParams: {},
      bodyTemplate: '''{
  "code": {code},
  "language": "dart",
  "input": "{stdin}"
}''',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: '',
      executionTimePath: 'timeStamp',
      memoryPath: '',
      isDefault: false,
    ),
    CompilerPreset(
      id: 'preset_replit',
      name: 'Replit',
      endpointUrl: 'https://your-replit-url',
      httpMethod: 'POST',
      authType: 'Bearer Token',
      authValue: 'YOUR_TOKEN',
      headers: {
        'Content-Type': 'application/json',
      },
      queryParams: {},
      bodyTemplate: '''{
  "code": {code},
  "language": "dart",
  "stdin": "{stdin}"
}''',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      executionTimePath: 'time',
      memoryPath: 'memory',
      isDefault: false,
    ),
    CompilerPreset(
      id: 'preset_hackerearth',
      name: 'HackerEarth',
      endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: 'YOUR_CLIENT_SECRET',
      headers: {
        'client-secret': 'YOUR_CLIENT_SECRET',
        'Content-Type': 'application/json'
      },
      queryParams: {},
      bodyTemplate: '''{
  "source": {code},
  "lang": "DART",
  "input": "{stdin}",
  "time_limit": 5,
  "memory_limit": 262144
}''',
      stdoutPath: 'result.run_status.output',
      stderrPath: 'result.run_status.stderr',
      errorPath: 'result.compile_status',
      executionTimePath: 'result.run_status.time_used',
      memoryPath: 'result.run_status.memory_used',
      isDefault: false,
    ),
    CompilerPreset(
      id: 'preset_blank',
      name: 'Blank',
      endpointUrl: 'https://example.com/api/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      queryParams: {},
      bodyTemplate: '''{
  "code": {code},
  "language": "dart",
  "stdin": "{stdin}"
}''',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      executionTimePath: '',
      memoryPath: '',
      isDefault: false,
    ),
  ];

  static const String defaultFileContent = '''// Welcome to DartMini IDE!
import 'dart:io';

void main() {
  print('Hello, Dart 3.5+ from DartMini IDE!');

  // Example of using stdin
  // Enter input in the run settings (if supported by active preset)
  // String? name = stdin.readLineSync();
  // print('Hello, \$name');
}
''';
}