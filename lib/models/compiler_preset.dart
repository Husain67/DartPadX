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
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'

  @HiveField(5)
  String authValue; // Used based on authType

  @HiveField(6)
  Map<String, String> headers;

  @HiveField(7)
  Map<String, String> queryParams;

  @HiveField(8)
  String requestBodyTemplate; // JSON with {code}, {stdin}, {language}

  @HiveField(9)
  String responseStdoutPath;

  @HiveField(10)
  String responseStderrPath;

  @HiveField(11)
  String responseErrorPath;

  @HiveField(12)
  String responseTimePath;

  @HiveField(13)
  String responseMemoryPath;

  @HiveField(14)
  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.responseStdoutPath,
    required this.responseStderrPath,
    required this.responseErrorPath,
    required this.responseTimePath,
    required this.responseMemoryPath,
    required this.isDefault,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? responseStdoutPath,
    String? responseStderrPath,
    String? responseErrorPath,
    String? responseTimePath,
    String? responseMemoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseTimePath: responseTimePath ?? this.responseTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
