import '../models/compiler_preset.dart';

class AppConstants {
  static const String appName = 'DartMini';
  static const String version = 'beta';

  static const String oneCompilerApiKey =
      'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  static const String defaultDartCode = '''void main() {
  print('Hello, DartMini IDE!');

  int a = 5;
  int b = 10;
  print('Sum: \${a + b}');
}''';

  static List<CompilerPreset> get defaultPresets => [
        CompilerPreset(
          id: 'one_compiler_default',
          name: 'OneCompiler (Default)',
          url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          method: 'POST',
          authType: 'API-Key Header',
          authValue: oneCompilerApiKey,
          headers: {
            'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
            'x-rapidapi-key': oneCompilerApiKey,
            'content-type': 'application/json',
          },
          bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '', // N/A
        ),
        CompilerPreset(
          id: 'piston_default',
          name: 'Piston API',
          url: 'https://emkc.org/api/v2/piston/execute',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"name": "main.dart", "content": {code}}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
          executionTimePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: 'jdoodle_default',
          name: 'JDoodle',
          url: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          authType: 'None', // Sent in body
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": {code}, "language": "dart", "versionIndex": "4", "stdin": "{stdin}"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          id: 'replit_default',
          name: 'Replit API',
          url: 'https://api.replit.com/v1/repls/execute',
          method: 'POST',
          authType: 'Bearer Token',
          authValue: 'YOUR_REPLIT_API_KEY',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"repl": "dart", "code": {code}, "stdin": "{stdin}"}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'error',
          executionTimePath: 'time',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          id: 'codex_default',
          name: 'CodeX API',
          url: 'https://api.codex.jaagrav.in',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"code": {code}, "language": "dart", "input": "{stdin}"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: 'hackerearth_default',
          name: 'HackerEarth API',
          url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          method: 'POST',
          authType: 'API-Key Header',
          authValue: 'YOUR_CLIENT_SECRET',
          headers: {'client-secret': 'YOUR_CLIENT_SECRET', 'Content-Type': 'application/json'},
          bodyTemplate: '{"lang": "DART", "source": {code}, "input": "{stdin}", "memory_limit": 262144, "time_limit": 5}',
          stdoutPath: 'result.run_status.output',
          stderrPath: 'result.run_status.stderr',
          errorPath: 'result.compile_status',
          executionTimePath: 'result.run_status.time_used',
          memoryPath: 'result.run_status.memory_used',
        ),
        CompilerPreset(
          id: 'blank_default',
          name: 'Blank Preset',
          url: 'https://api.example.com/execute',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"code": {code}}',
          stdoutPath: 'result.out',
          stderrPath: 'result.err',
          errorPath: 'error',
          executionTimePath: 'time',
          memoryPath: 'memory',
        ),
      ];

  static const List<Map<String, String>> examples = [
    {
      'title': 'Hello World',
      'code': '''void main() {
  print('Hello World!');
}''',
    },
    {
      'title': 'Basic Arithmetic',
      'code': '''void main() {
  int a = 15;
  int b = 7;
  print('Addition: \${a + b}');
  print('Subtraction: \${a - b}');
  print('Multiplication: \${a * b}');
  print('Division: \${a / b}');
  print('Modulo: \${a % b}');
}''',
    },
    {
      'title': 'Lists & Loops',
      'code': '''void main() {
  List<String> fruits = ['Apple', 'Banana', 'Cherry'];

  for (int i = 0; i < fruits.length; i++) {
    print('Fruit \${i + 1}: \${fruits[i]}');
  }
}''',
    },
    {
      'title': 'Classes',
      'code': '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p1 = Person('Alice', 25);
  p1.introduce();
}''',
    },
    {
      'title': 'Async/Await',
      'code': '''Future<void> main() async {
  print('Fetching data...');
  String data = await fetchData();
  print('Received: \$data');
}

Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return 'Data from server';
}''',
    },
  ];
}
