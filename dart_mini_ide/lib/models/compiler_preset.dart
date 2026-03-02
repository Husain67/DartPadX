import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String platformName;

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
  String stdoutPath;

  @HiveField(9)
  String stderrPath;

  @HiveField(10)
  String errorPath;

  @HiveField(11)
  String executionTimePath;

  @HiveField(12)
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.platformName,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

  CompilerPreset copyWith({
    String? id,
    String? platformName,
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
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platformName': platformName,
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

  factory CompilerPreset.fromJson(Map<String, dynamic> json) => CompilerPreset(
        id: json['id'] as String,
        platformName: json['platformName'] as String,
        endpointUrl: json['endpointUrl'] as String,
        httpMethod: json['httpMethod'] as String,
        authType: json['authType'] as String,
        headers: Map<String, String>.from(json['headers'] ?? {}),
        queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
        requestBodyTemplate: json['requestBodyTemplate'] as String,
        stdoutPath: json['stdoutPath'] as String,
        stderrPath: json['stderrPath'] as String,
        errorPath: json['errorPath'] as String,
        executionTimePath: json['executionTimePath'] as String,
        memoryPath: json['memoryPath'] as String,
      );
}
