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
  String stdoutPath;

  @HiveField(9)
  String stderrPath;

  @HiveField(10)
  String errorPath;

  @HiveField(11)
  String executionTimePath;

  @HiveField(12)
  String memoryPath;

  @HiveField(13)
  bool isPreloaded;

  CompilerPreset({
    required this.id,
    required this.name,
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
    this.isPreloaded = false,
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
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isPreloaded,
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
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isPreloaded: isPreloaded ?? this.isPreloaded,
    );
  }
}
