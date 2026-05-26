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
  String httpMethod; // POST, GET, PUT

  @HiveField(4)
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  String? authKey; // Holds token or key

  @HiveField(6)
  List<Map<String, String>> headers;

  @HiveField(7)
  List<Map<String, String>> queryParams;

  @HiveField(8)
  String bodyTemplate;

  @HiveField(9)
  String stdoutPath;

  @HiveField(10)
  String stderrPath;

  @HiveField(11)
  String errorPath;

  @HiveField(12)
  String executionTimePath;

  @HiveField(13)
  String memoryPath;

  @HiveField(14)
  bool isReadOnly;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authKey,
    this.headers = const [],
    this.queryParams = const [],
    this.bodyTemplate = '{"content": "{code}"}',
    this.stdoutPath = 'output',
    this.stderrPath = 'error',
    this.errorPath = 'error',
    this.executionTimePath = 'cpuTime',
    this.memoryPath = 'memory',
    this.isReadOnly = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authKey,
    List<Map<String, String>>? headers,
    List<Map<String, String>>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isReadOnly,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}
