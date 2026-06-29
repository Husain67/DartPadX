import 'dart:convert';

class CompilerPreset {
  String id;
  String name;
  String endpointUrl;
  String method;
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'
  String authValue;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String timePath;
  String memoryPath;
  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.method,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.timePath,
    required this.memoryPath,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'method': method,
      'authType': authType,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'timePath': timePath,
      'memoryPath': memoryPath,
      'isDefault': isDefault,
    };
  }

  factory CompilerPreset.fromMap(Map<String, dynamic> map) {
    return CompilerPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      endpointUrl: map['endpointUrl'] ?? '',
      method: map['method'] ?? 'POST',
      authType: map['authType'] ?? 'None',
      authValue: map['authValue'] ?? '',
      headers: Map<String, String>.from(map['headers'] ?? {}),
      queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
      bodyTemplate: map['bodyTemplate'] ?? '',
      stdoutPath: map['stdoutPath'] ?? '',
      stderrPath: map['stderrPath'] ?? '',
      errorPath: map['errorPath'] ?? '',
      timePath: map['timePath'] ?? '',
      memoryPath: map['memoryPath'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CompilerPreset.fromJson(String source) => CompilerPreset.fromMap(json.decode(source));
}
