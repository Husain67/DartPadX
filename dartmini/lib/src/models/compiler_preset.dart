import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String endpoint;

  @HiveField(3)
  final String method; // POST, GET, etc.

  @HiveField(4)
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  final String authValue;

  @HiveField(6)
  final Map<String, String> headers;

  @HiveField(7)
  final Map<String, String> queryParams;

  @HiveField(8)
  final String requestBodyTemplate;

  @HiveField(9)
  final String stdoutPath;

  @HiveField(10)
  final String stderrPath;

  @HiveField(11)
  final String errorPath;

  @HiveField(12)
  final String executionTimePath;

  @HiveField(13)
  final String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.method,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

  static List<CompilerPreset> getDefaultPresets() {
    return [
      defaultOneCompiler(),
      defaultJDoodle(),
      defaultPiston(),
      defaultReplit(),
      defaultCodeX(),
      defaultHackerEarth(),
      blankPreset(),
    ];
  }

  static CompilerPreset defaultOneCompiler() {
    const String apiKey = String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

    return CompilerPreset(
      id: 'onecompiler_default',
      name: 'OneCompiler',
      endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      method: 'POST',
      authType: 'API-Key Header',
      authValue: apiKey,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      queryParams: {},
      requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
    );
  }

  static CompilerPreset defaultJDoodle() {
    return CompilerPreset(
      id: 'jdoodle_default',
      name: 'JDoodle',
      endpoint: 'https://api.jdoodle.com/v1/execute',
      method: 'POST',
      authType: 'None', // Sent in body usually, but can be configured
      authValue: '',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
      stdoutPath: 'output',
      stderrPath: '',
      errorPath: 'error',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
    );
  }

  static CompilerPreset defaultPiston() {
    return CompilerPreset(
      id: 'piston_default',
      name: 'Piston (EngineerMan)',
      endpoint: 'https://emacs.emkc.org/api/v2/piston/execute',
      method: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{\n  "language": "dart",\n  "version": "2.19.6",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'message',
      executionTimePath: '',
      memoryPath: '',
    );
  }

  static CompilerPreset defaultReplit() {
    return CompilerPreset(
      id: 'replit_default',
      name: 'Replit (Concept)',
      endpoint: 'https://replit.com/api/v1/run', // Conceptual endpoint
      method: 'POST',
      authType: 'Bearer Token',
      authValue: 'YOUR_REPLIT_TOKEN',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{\n  "language": "dart",\n  "code": "{code}"\n}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      executionTimePath: '',
      memoryPath: '',
    );
  }

  static CompilerPreset defaultCodeX() {
    return CompilerPreset(
      id: 'codex_default',
      name: 'CodeX API',
      endpoint: 'https://api.codex.jaagrav.in',
      method: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
    );
  }

  static CompilerPreset defaultHackerEarth() {
    return CompilerPreset(
      id: 'hackerearth_default',
      name: 'HackerEarth (Concept)',
      endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      method: 'POST',
      authType: 'API-Key Header',
      authValue: 'YOUR_CLIENT_SECRET',
      headers: {
        'Content-Type': 'application/json',
        'client-secret': 'YOUR_CLIENT_SECRET'
      },
      queryParams: {},
      requestBodyTemplate: '{\n  "source": "{code}",\n  "lang": "DART",\n  "input": "{stdin}"\n}',
      stdoutPath: 'result.run_status.output',
      stderrPath: 'result.run_status.stderr',
      errorPath: 'errors',
      executionTimePath: 'result.run_status.time_used',
      memoryPath: 'result.run_status.memory_used',
    );
  }

  static CompilerPreset blankPreset() {
    return CompilerPreset(
      id: 'blank_default',
      name: 'Blank Custom API',
      endpoint: '',
      method: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{\n  "code": "{code}"\n}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      executionTimePath: '',
      memoryPath: '',
    );
  }

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }
}
