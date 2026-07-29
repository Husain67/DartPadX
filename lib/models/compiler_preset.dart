import 'package:uuid/uuid.dart';

class CompilerPreset {
  final String id;
  String name;
  String endpointUrl;
  String httpMethod; // GET, POST, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpointUrl,
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
  }) : id = id ?? const Uuid().v4();

  CompilerPreset copyWith({
    String? name,
    String? endpointUrl,
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
  }) {
    return CompilerPreset(
      id: id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
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
    };
  }

  factory CompilerPreset.fromMap(Map<String, dynamic> map) {
    return CompilerPreset(
      id: map['id'] as String,
      name: map['name'] as String,
      endpointUrl: map['endpointUrl'] as String,
      httpMethod: map['httpMethod'] as String? ?? 'POST',
      authType: map['authType'] as String? ?? 'None',
      headers: Map<String, String>.from(map['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(map['queryParams'] as Map? ?? {}),
      requestBodyTemplate: map['requestBodyTemplate'] as String? ?? '',
      stdoutPath: map['stdoutPath'] as String? ?? '',
      stderrPath: map['stderrPath'] as String? ?? '',
      errorPath: map['errorPath'] as String? ?? '',
      executionTimePath: map['executionTimePath'] as String? ?? '',
      memoryPath: map['memoryPath'] as String? ?? '',
    );
  }
}
