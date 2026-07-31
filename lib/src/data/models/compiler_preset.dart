import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpointUrl;

  @HiveField(3)
  String method; // GET, POST, PUT

  @HiveField(4)
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String bodyTemplate;

  @HiveField(8)
  String stdoutPath;

  @HiveField(9)
  String stderrPath;

  @HiveField(10)
  String errorPath;

  @HiveField(11)
  String executionTimePath;

  @HiveField(12)
  String memoryPath;

  @HiveField(13)
  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isDefault = false,
  });

  factory CompilerPreset.defaultOneCompiler() {
    return CompilerPreset(
      id: 'default_onecompiler',
      name: 'OneCompiler (Default)',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      method: 'POST',
      authType: 'API-Key Header',
      headers: {
        'x-rapidapi-key': const String.fromEnvironment('ONE_COMPILER_KEY'),
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: 'memory',
      isDefault: true,
    );
  }

  factory CompilerPreset.jdoodle() {
    return CompilerPreset(
      id: 'preset_jdoodle',
      name: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      method: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: '',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
    );
  }

  factory CompilerPreset.piston() {
    return CompilerPreset(
      id: 'preset_piston',
      name: 'Piston (emkc.org)',
      endpointUrl: 'https://emkc.org/api/v2/piston/execute',
      method: 'POST',
      authType: 'None',
      headers: {
        'Content-Type': 'application/json',
      },
      bodyTemplate: '{"language": "dart", "version": "*", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'message',
      executionTimePath: '',
      memoryPath: '',
    );
  }

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
