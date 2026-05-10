import 'package:hive/hive.dart';

part 'preset_model.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String method; // POST, GET, PUT

  @HiveField(4)
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  String authValue;

  @HiveField(6)
  Map<String, String> headers;

  @HiveField(7)
  Map<String, String> queryParams;

  @HiveField(8)
  String bodyTemplate; // JSON with {code}, {stdin}, {language}

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
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '{"content": "{code}"}',
    this.stdoutPath = 'stdout',
    this.stderrPath = 'stderr',
    this.errorPath = 'error',
    this.executionTimePath = 'time',
    this.memoryPath = 'memory',
    this.isReadOnly = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
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
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'method': method,
      'authType': authType,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isReadOnly': isReadOnly,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      authValue: json['authValue'] as String? ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] as String? ?? '{"content": "{code}"}',
      stdoutPath: json['stdoutPath'] as String? ?? 'stdout',
      stderrPath: json['stderrPath'] as String? ?? 'stderr',
      errorPath: json['errorPath'] as String? ?? 'error',
      executionTimePath: json['executionTimePath'] as String? ?? 'time',
      memoryPath: json['memoryPath'] as String? ?? 'memory',
      isReadOnly: json['isReadOnly'] as bool? ?? false,
    );
  }
}
