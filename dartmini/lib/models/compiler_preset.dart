import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  String authValue;

  @HiveField(6)
  Map<String, String> headers;

  @HiveField(7)
  Map<String, String> queryParams;

  @HiveField(8)
  String bodyTemplate;

  @HiveField(9)
  String stdoutPath;

  @HiveField(10)
  String stderrPath;

  @HiveField(11)
  String errorPath;

  @HiveField(12)
  String executionTimePath;

  @HiveField(13)
  String memoryPath;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
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
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
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
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }
}
