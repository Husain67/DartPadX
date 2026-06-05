import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String platformName;

  @HiveField(2)
  final String endpointUrl;

  @HiveField(3)
  final String httpMethod;

  @HiveField(4)
  final String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'

  @HiveField(5)
  final Map<String, String> dynamicHeaders;

  @HiveField(6)
  final Map<String, String> dynamicQueryParams;

  @HiveField(7)
  final String requestBodyTemplate;

  @HiveField(8)
  final String stdoutPath;

  @HiveField(9)
  final String stderrPath;

  @HiveField(10)
  final String errorPath;

  @HiveField(11)
  final String executionTimePath;

  @HiveField(12)
  final String memoryPath;

  @HiveField(13)
  final bool isDefault;

  CompilerPreset({
    required this.id,
    required this.platformName,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    this.dynamicHeaders = const {},
    this.dynamicQueryParams = const {},
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
    this.isDefault = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? platformName,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? dynamicHeaders,
    Map<String, String>? dynamicQueryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      dynamicHeaders: dynamicHeaders ?? this.dynamicHeaders,
      dynamicQueryParams: dynamicQueryParams ?? this.dynamicQueryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
