import 'dart:convert';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String method; // GET, POST, PUT
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  final String authKey; // Key name for header or query param
  final String authValue; // Actual token or key
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate;
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;
  final bool isReadOnly;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.authKey = '',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isReadOnly = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    String? authKey,
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
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'method': method,
      'authType': authType,
      'authKey': authKey,
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

  factory CompilerPreset.fromMap(Map<String, dynamic> map) {
    return CompilerPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      endpoint: map['endpoint'] ?? '',
      method: map['method'] ?? 'POST',
      authType: map['authType'] ?? 'None',
      authKey: map['authKey'] ?? '',
      authValue: map['authValue'] ?? '',
      headers: Map<String, String>.from(map['headers'] ?? {}),
      queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
      bodyTemplate: map['bodyTemplate'] ?? '',
      stdoutPath: map['stdoutPath'] ?? '',
      stderrPath: map['stderrPath'] ?? '',
      errorPath: map['errorPath'] ?? '',
      executionTimePath: map['executionTimePath'] ?? '',
      memoryPath: map['memoryPath'] ?? '',
      isReadOnly: map['isReadOnly'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CompilerPreset.fromJson(String source) => CompilerPreset.fromMap(json.decode(source));
}
