import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String endpoint;

  @HiveField(3)
  final String httpMethod; // POST, GET, PUT

  @HiveField(4)
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  final Map<String, String> headers;

  @HiveField(6)
  final Map<String, String> queryParams;

  @HiveField(7)
  final String bodyTemplate;

  @HiveField(8)
  final String stdoutPath;

  @HiveField(9)
  final String stderrPath;

  @HiveField(10)
  final String errorPath;

  @HiveField(11)
  final String executionTimePath;

  @HiveField(12)
  final String memoryPath;

  @HiveField(13)
  final bool isDefault;

  @HiveField(14)
  final bool isPreloaded;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
    this.isDefault = false,
    this.isPreloaded = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? httpMethod,
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
    bool? isPreloaded,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
      isPreloaded: isPreloaded ?? this.isPreloaded,
    );
  }
}
