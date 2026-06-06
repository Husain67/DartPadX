import 'dart:convert';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String method; // GET, POST, PUT
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  final List<Map<String, String>> headers; // e.g., [{'key': 'Authorization', 'value': 'Bearer ...'}]
  final List<Map<String, String>> queryParams; // e.g., [{'key': 'lang', 'value': 'dart'}]
  final String bodyTemplate; // JSON template with placeholders {code}, {stdin}, {language}

  // Response mapping using dot notation
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;

  final bool isDefault;
  final bool isSystem;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.method,
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
    this.isSystem = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    List<Map<String, String>>? headers,
    List<Map<String, String>>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefault,
    bool? isSystem,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
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
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'method': method,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isDefault': isDefault,
      'isSystem': isSystem,
    };
  }

  factory CompilerPreset.fromMap(Map<String, dynamic> map) {
    return CompilerPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      endpoint: map['endpoint'] ?? '',
      method: map['method'] ?? 'POST',
      authType: map['authType'] ?? 'None',
      headers: List<Map<String, String>>.from(
          (map['headers'] as List<dynamic>? ?? []).map((x) => Map<String, String>.from(x))),
      queryParams: List<Map<String, String>>.from(
          (map['queryParams'] as List<dynamic>? ?? []).map((x) => Map<String, String>.from(x))),
      bodyTemplate: map['bodyTemplate'] ?? '',
      stdoutPath: map['stdoutPath'] ?? '',
      stderrPath: map['stderrPath'] ?? '',
      errorPath: map['errorPath'] ?? '',
      executionTimePath: map['executionTimePath'] ?? '',
      memoryPath: map['memoryPath'] ?? '',
      isDefault: map['isDefault'] ?? false,
      isSystem: map['isSystem'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CompilerPreset.fromJson(String source) =>
      CompilerPreset.fromMap(json.decode(source));
}
