import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpointUrl;

  @HiveField(3)
  String httpMethod;

  @HiveField(4)
  String authType;

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String requestBodyTemplate;

  @HiveField(8)
  String responseStdoutPath;

  @HiveField(9)
  String responseStderrPath;

  @HiveField(10)
  String responseErrorPath;

  @HiveField(11)
  String responseExecutionTimePath;

  @HiveField(12)
  String responseMemoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.responseStdoutPath,
    required this.responseStderrPath,
    required this.responseErrorPath,
    required this.responseExecutionTimePath,
    required this.responseMemoryPath,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? responseStdoutPath,
    String? responseStderrPath,
    String? responseErrorPath,
    String? responseExecutionTimePath,
    String? responseMemoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseExecutionTimePath: responseExecutionTimePath ?? this.responseExecutionTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'responseStdoutPath': responseStdoutPath,
      'responseStderrPath': responseStderrPath,
      'responseErrorPath': responseErrorPath,
      'responseExecutionTimePath': responseExecutionTimePath,
      'responseMemoryPath': responseMemoryPath,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'],
      endpointUrl: json['endpointUrl'],
      httpMethod: json['httpMethod'],
      authType: json['authType'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'],
      responseStdoutPath: json['responseStdoutPath'],
      responseStderrPath: json['responseStderrPath'],
      responseErrorPath: json['responseErrorPath'],
      responseExecutionTimePath: json['responseExecutionTimePath'],
      responseMemoryPath: json['responseMemoryPath'],
    );
  }
}
