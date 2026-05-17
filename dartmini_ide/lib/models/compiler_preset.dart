import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  String httpMethod; // POST, GET, PUT

  @HiveField(4)
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  String authValue;

  @HiveField(6)
  String authKey; // For API-Key Header or Query Param

  @HiveField(7)
  Map<String, String> headers;

  @HiveField(8)
  Map<String, String> queryParams;

  @HiveField(9)
  String requestBodyTemplate;

  @HiveField(10)
  String stdoutPath;

  @HiveField(11)
  String stderrPath;

  @HiveField(12)
  String errorPath;

  @HiveField(13)
  String executionTimePath;

  @HiveField(14)
  String memoryPath;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.authKey = '',
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
    String? authValue,
    String? authKey,
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
      authValue: authValue ?? this.authValue,
      authKey: authKey ?? this.authKey,
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
}
