import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpointUrl;

  @HiveField(3)
  String httpMethod;

  @HiveField(4)
  String authType;

  @HiveField(5)
  String? authValue;

  @HiveField(6)
  Map<String, String> headers;

  @HiveField(7)
  Map<String, String> queryParams;

  @HiveField(8)
  String bodyTemplate;

  @HiveField(9)
  ResponseMapping responseMapping;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authValue,
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '{"code": "{code}", "language": "{language}"}',
    required this.responseMapping,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'responseMapping': responseMapping.toJson(),
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'],
      endpointUrl: json['endpointUrl'],
      httpMethod: json['httpMethod'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      authValue: json['authValue'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] ?? '{"code": "{code}"}',
      responseMapping: ResponseMapping.fromJson(json['responseMapping'] ?? {}),
    );
  }
}

@HiveType(typeId: 2)
class ResponseMapping extends HiveObject {
  @HiveField(0)
  String stdoutPath;

  @HiveField(1)
  String stderrPath;

  @HiveField(2)
  String errorPath;

  @HiveField(3)
  String executionTimePath;

  @HiveField(4)
  String memoryPath;

  ResponseMapping({
    this.stdoutPath = 'output',
    this.stderrPath = 'error',
    this.errorPath = 'error',
    this.executionTimePath = 'time',
    this.memoryPath = 'memory',
  });

  Map<String, dynamic> toJson() {
    return {
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
    };
  }

  factory ResponseMapping.fromJson(Map<String, dynamic> json) {
    return ResponseMapping(
      stdoutPath: json['stdoutPath'] ?? 'output',
      stderrPath: json['stderrPath'] ?? 'error',
      errorPath: json['errorPath'] ?? 'error',
      executionTimePath: json['executionTimePath'] ?? 'time',
      memoryPath: json['memoryPath'] ?? 'memory',
    );
  }
}
