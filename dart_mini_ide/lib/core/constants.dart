import 'package:flutter/material.dart';
import '../models/compiler_preset.dart';

class AppConstants {
  static const Color bgColorStart = Color(0xFF050505);
  static const Color bgColorEnd = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFFACC15);
  static const Color toolbarBtnBg = Color(0xFFF9F9F9);
  static const Color toolbarBtnBorder = Color(0xFFE0E0E0);
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.greenAccent;

  static const String defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  static final List<CompilerPreset> predefinedPresets = [
    CompilerPreset(
      id: 'pre_onecompiler',
      name: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authKey: 'X-RapidAPI-Key',
      authValue: defaultOneCompilerKey,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      },
      queryParams: {},
      requestBodyTemplate: '{"language":"dart","stdin":"{stdin}","files":[{"name":"main.dart","content":"{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
    ),
    CompilerPreset(
      id: 'pre_jdoodle',
      name: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None',
      authKey: '',
      authValue: '',
      headers: {
        'Content-Type': 'application/json',
      },
      queryParams: {},
      requestBodyTemplate: '{"clientId":"YOUR_CLIENT_ID","clientSecret":"YOUR_CLIENT_SECRET","script":"{code}","stdin":"{stdin}","language":"dart","versionIndex":"4"}',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
    ),
    CompilerPreset(
      id: 'pre_piston',
      name: 'Piston',
      endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
      httpMethod: 'POST',
      authType: 'None',
      authKey: '',
      authValue: '',
      headers: {
        'Content-Type': 'application/json',
      },
      queryParams: {},
      requestBodyTemplate: '{"language":"dart","version":"3.3.3","files":[{"content":"{code}"}],"stdin":"{stdin}"}',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'compile.stderr',
      executionTimePath: '',
      memoryPath: '',
    ),
    CompilerPreset(
      id: 'pre_replit',
      name: 'Replit',
      endpointUrl: 'https://example-replit-endpoint.com/run',
      httpMethod: 'POST',
      authType: 'None',
      authKey: '',
      authValue: '',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{"code":"{code}","stdin":"{stdin}"}',
      stdoutPath: 'out',
      stderrPath: 'err',
      errorPath: 'error',
      executionTimePath: 'time',
      memoryPath: 'mem',
    ),
    CompilerPreset(
      id: 'pre_codex',
      name: 'CodeX',
      endpointUrl: 'https://api.codex.jaagrav.in',
      httpMethod: 'POST',
      authType: 'None',
      authKey: '',
      authValue: '',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      queryParams: {},
      requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      executionTimePath: '',
      memoryPath: '',
    ),
    CompilerPreset(
      id: 'pre_hackerearth',
      name: 'HackerEarth',
      endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authKey: 'client-secret',
      authValue: 'YOUR_SECRET',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{"lang":"DART","source":"{code}","input":"{stdin}"}',
      stdoutPath: 'result.run_status.output',
      stderrPath: 'result.run_status.stderr',
      errorPath: 'result.compile_status',
      executionTimePath: 'result.run_status.time_used',
      memoryPath: 'result.run_status.memory_used',
    ),
    CompilerPreset(
      id: 'pre_blank',
      name: 'Blank',
      endpointUrl: '',
      httpMethod: 'POST',
      authType: 'None',
      authKey: '',
      authValue: '',
      headers: {},
      queryParams: {},
      requestBodyTemplate: '',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
    ),
  ];

  static const String examplesGalleryJson = '''
  [
    {
      "name": "Hello World",
      "code": "void main() {\\n  print('Hello, DartMini IDE!');\\n}"
    },
    {
      "name": "Input/Output",
      "code": "import 'dart:io';\\n\\nvoid main() {\\n  print('Enter your name:');\\n  String? name = stdin.readLineSync();\\n  print('Hello, \$name!');\\n}"
    },
    {
      "name": "List",
      "code": "void main() {\\n  List<int> numbers = [1, 2, 3, 4, 5];\\n  for (var number in numbers) {\\n    print(number);\\n  }\\n}"
    },
    {
      "name": "Class",
      "code": "class Person {\\n  String name;\\n  int age;\\n\\n  Person(this.name, this.age);\\n\\n  void greet() {\\n    print('Hello, my name is \$name and I am \$age years old.');\\n  }\\n}\\n\\nvoid main() {\\n  var person = Person('Alice', 30);\\n  person.greet();\\n}"
    },
    {
      "name": "Async",
      "code": "Future<void> main() async {\\n  print('Fetching data...');\\n  await Future.delayed(Duration(seconds: 2));\\n  print('Data fetched!');\\n}"
    }
  ]
  ''';
}
