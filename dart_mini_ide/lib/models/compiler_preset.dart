import 'package:uuid/uuid.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String method; // POST, GET
  final String authType; // None, Header, Bearer
  final String authKey; // usually empty or a specific header name
  final String authValue;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate;

  // Mapping paths (dot notation)
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String timePath;
  final String memoryPath;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.authKey = '',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    required this.bodyTemplate,
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.timePath = '',
    this.memoryPath = '',
  }) : id = id ?? const Uuid().v4();

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
    String? timePath,
    String? memoryPath,
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
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  Map<String, dynamic> toJson() {
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
      'timePath': timePath,
      'memoryPath': memoryPath,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'],
      endpoint: json['endpoint'],
      method: json['method'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      authKey: json['authKey'] ?? '',
      authValue: json['authValue'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] ?? '',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      timePath: json['timePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
    );
  }
}
