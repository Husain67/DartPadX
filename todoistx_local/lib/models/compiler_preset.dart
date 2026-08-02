import 'dart:convert';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String httpMethod;
  final String authType;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String requestBodyTemplate;

  // Mapping paths (dot notation)
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;

  final bool isDefaultPreset; // Usually true only for the built-in OneCompiler

  const CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isDefaultPreset = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefaultPreset,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefaultPreset: isDefaultPreset ?? this.isDefaultPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'httpMethod': httpMethod,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isDefaultPreset': isDefaultPreset,
    };
  }

  factory CompilerPreset.fromMap(Map<String, dynamic> map) {
    return CompilerPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      endpoint: map['endpoint'] ?? '',
      httpMethod: map['httpMethod'] ?? 'POST',
      authType: map['authType'] ?? 'None',
      headers: Map<String, String>.from(map['headers'] ?? {}),
      queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
      requestBodyTemplate: map['requestBodyTemplate'] ?? '',
      stdoutPath: map['stdoutPath'] ?? '',
      stderrPath: map['stderrPath'] ?? '',
      errorPath: map['errorPath'] ?? '',
      executionTimePath: map['executionTimePath'] ?? '',
      memoryPath: map['memoryPath'] ?? '',
      isDefaultPreset: map['isDefaultPreset'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CompilerPreset.fromJson(String source) => CompilerPreset.fromMap(json.decode(source));
}
