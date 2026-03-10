import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class AppConstants {
  static const String appName = 'DartMini';
  static const String appVersion = 'beta';

  // Storage
  static const String fileBoxName = 'dart_files';
  static const String settingsBoxName = 'dart_settings';

  static final CodeFile defaultMainFile = CodeFile(
    id: 'main',
    name: 'main.dart',
    content: '''import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');
  // Read stdin
  // String? name = stdin.readLineSync();
  // print('Hello \$name');
}''',
  );

  static final List<CodeFile> defaultExamples = [
    defaultMainFile,
    CodeFile(
      id: 'example_io',
      name: 'input_output.dart',
      content: '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
    ),
    CodeFile(
      id: 'example_list',
      name: 'list_example.dart',
      content: '''void main() {
  List<int> numbers = [1, 2, 3, 4, 5];
  for(int num in numbers) {
    print('Number: \$num');
  }
}''',
    ),
    CodeFile(
      id: 'example_class',
      name: 'class_example.dart',
      content: '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p = Person('Jules', 25);
  p.introduce();
}''',
    ),
    CodeFile(
      id: 'example_async',
      name: 'async_example.dart',
      content: '''Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched successfully!');
}''',
    ),
  ];

  static final CompilerPreset oneCompilerDefault = CompilerPreset(
    id: 'onecompiler_default',
    platformName: 'OneCompiler',
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
    timePath: 'executionTime',
    memoryPath: '', // OneCompiler doesn't return memory reliably in the same format
  );

  static final List<CompilerPreset> preloadedPresets = [
    oneCompilerDefault,
    CompilerPreset(
      id: 'jdoodle',
      platformName: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None', // Sent in body
      headers: {'content-type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '''{
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
      timePath: 'cpuTime',
      memoryPath: 'memory',
    ),
    CompilerPreset(
      id: 'piston',
      platformName: 'Piston',
      endpointUrl: 'https://emkc.org/api/v2/piston/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {'content-type': 'application/json'},
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
      errorPath: 'message',
      timePath: '',
      memoryPath: '',
    ),
    CompilerPreset(
      id: 'replit',
      platformName: 'Replit',
      endpointUrl: 'https://replit.com/api/v1/execute',
      httpMethod: 'POST',
      authType: 'Bearer Token',
      headers: {'content-type': 'application/json', 'Authorization': 'Bearer YOUR_TOKEN'},
      queryParams: {},
      requestBodyTemplate: '''{ "language": "dart", "code": {code} }''',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      timePath: 'time',
      memoryPath: 'memory',
    ),
    CompilerPreset(
       id: 'codex',
       platformName: 'CodeX',
       endpointUrl: 'https://api.codex.jaagrav.in',
       httpMethod: 'POST',
       authType: 'None',
       headers: {'content-type': 'application/x-www-form-urlencoded'},
       queryParams: {},
       requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
       stdoutPath: 'output',
       stderrPath: 'error',
       errorPath: 'error',
       timePath: '',
       memoryPath: '',
    ),
    CompilerPreset(
      id: 'hackerearth',
      platformName: 'HackerEarth',
      endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      headers: {'content-type': 'application/json', 'client-secret': 'YOUR_SECRET'},
      queryParams: {},
      requestBodyTemplate: '''{ "lang": "DART", "source": {code}, "input": "{stdin}" }''',
      stdoutPath: 'result.run_status.output',
      stderrPath: 'result.run_status.stderr',
      errorPath: 'errors',
      timePath: 'result.run_status.time_used',
      memoryPath: 'result.run_status.memory_used',
    ),
    CompilerPreset(
      id: 'blank',
      platformName: 'Blank Preset',
      endpointUrl: 'https://',
      httpMethod: 'POST',
      authType: 'None',
      headers: {},
      queryParams: {},
      requestBodyTemplate: '{}',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      timePath: '',
      memoryPath: '',
    )
  ];
}
