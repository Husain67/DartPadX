import 'package:hive/hive.dart';

part 'preset_model.g.dart';

@HiveType(typeId: 1)
class PresetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String endpoint;

  @HiveField(3)
  final String method;

  @HiveField(4)
  final String authType;

  @HiveField(5)
  final String authValue;

  @HiveField(6)
  final Map<String, String> headers;

  @HiveField(7)
  final Map<String, String> queryParams;

  @HiveField(8)
  final String bodyTemplate;

  @HiveField(9)
  final String responseStdoutPath;

  @HiveField(10)
  final String responseStderrPath;

  @HiveField(11)
  final String responseErrorPath;

  @HiveField(12)
  final String responseTimePath;

  @HiveField(13)
  final String responseMemoryPath;

  PresetModel({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.method,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.responseStdoutPath,
    required this.responseStderrPath,
    required this.responseErrorPath,
    required this.responseTimePath,
    required this.responseMemoryPath,
  });

  PresetModel copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? responseStdoutPath,
    String? responseStderrPath,
    String? responseErrorPath,
    String? responseTimePath,
    String? responseMemoryPath,
  }) {
    return PresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseTimePath: responseTimePath ?? this.responseTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
    );
  }
}
