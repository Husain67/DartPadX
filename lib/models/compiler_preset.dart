import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpoint;

  @HiveField(3)
  String method;

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
  String timePath;

  @HiveField(13)
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.method,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.timePath,
    required this.memoryPath,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'endpoint': endpoint,
        'method': method,
        'authType': authType,
        'authValue': authValue,
        'headers': headers,
        'queryParams': queryParams,
        'bodyTemplate': bodyTemplate,
        'stdoutPath': stdoutPath,
        'stderrPath': stderrPath,
        'errorPath': errorPath,
        'timePath': timePath,
        'memoryPath': memoryPath,
      };

  factory CompilerPreset.fromJson(Map<String, dynamic> json) => CompilerPreset(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        endpoint: json['endpoint'] ?? '',
        method: json['method'] ?? 'POST',
        authType: json['authType'] ?? 'None',
        authValue: json['authValue'] ?? '',
        headers: Map<String, String>.from(json['headers'] ?? {}),
        queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
        bodyTemplate: json['bodyTemplate'] ?? '',
        stdoutPath: json['stdoutPath'] ?? '',
        stderrPath: json['stderrPath'] ?? '',
        errorPath: json['errorPath'] ?? '',
        timePath: json['timePath'] ?? '',
        memoryPath: json['memoryPath'] ?? '',
      );
}
