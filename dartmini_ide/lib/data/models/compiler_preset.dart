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
  String endpoint;

  @HiveField(3)
  String method; // GET, POST, PUT

  @HiveField(4)
  String authType; // None, Header, Bearer, Basic, Query

  @HiveField(5)
  String authValue;

  @HiveField(6)
  Map<String, String> headers;

  @HiveField(7)
  Map<String, String> queryParams;

  @HiveField(8)
  String bodyTemplate; // JSON template with {code}, {stdin}, {language}

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
  bool isReadOnly; // For pre-loaded presets

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.authValue = '',
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.bodyTemplate = '',
    this.responseStdoutPath = '',
    this.responseStderrPath = '',
    this.responseErrorPath = '',
    this.responseTimePath = '',
    this.responseMemoryPath = '',
    this.isReadOnly = false,
  })  : id = id ?? const Uuid().v4(),
        headers = headers ?? {},
        queryParams = queryParams ?? {};

  CompilerPreset copyWith({
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
    bool? isReadOnly,
  }) {
    return CompilerPreset(
      id: id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseTimePath: responseTimePath ?? this.responseTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}
