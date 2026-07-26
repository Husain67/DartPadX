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
  final String method; // POST, GET

  @HiveField(4)
  final String
      authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  final String authValue;

  @HiveField(6)
  final Map<String, String> headers;

  @HiveField(7)
  final Map<String, String> queryParams;

  @HiveField(8)
  final String bodyTemplate;

  // Response Mapping paths (dot notation)
  @HiveField(9)
  final String stdoutPath;

  @HiveField(10)
  final String stderrPath;

  @HiveField(11)
  final String errorPath;

  @HiveField(12)
  final String timePath;

  @HiveField(13)
  final String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.timePath = '',
    this.memoryPath = '',
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
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
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }
}
