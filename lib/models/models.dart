import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class FileState extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  bool isReadOnly;

  FileState({
    required this.id,
    required this.name,
    required this.content,
    this.isReadOnly = false,
  });

  FileState copyWith({
    String? id,
    String? name,
    String? content,
    bool? isReadOnly,
  }) {
    return FileState(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String method;

  @HiveField(4)
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'

  @HiveField(5)
  String authKey; // For header or query param name

  @HiveField(6)
  String authValue;

  @HiveField(7)
  Map<String, String> headers;

  @HiveField(8)
  Map<String, String> queryParams;

  @HiveField(9)
  String bodyTemplate;

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

  @HiveField(15)
  bool isPreloaded;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.authKey = '',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isPreloaded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'method': method,
      'authType': authType,
      'authKey': authKey,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isPreloaded': isPreloaded,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      authKey: json['authKey'] as String? ?? '',
      authValue: json['authValue'] as String? ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] as String? ?? '',
      stdoutPath: json['stdoutPath'] as String? ?? '',
      stderrPath: json['stderrPath'] as String? ?? '',
      errorPath: json['errorPath'] as String? ?? '',
      executionTimePath: json['executionTimePath'] as String? ?? '',
      memoryPath: json['memoryPath'] as String? ?? '',
      isPreloaded: json['isPreloaded'] as bool? ?? false,
    );
  }

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    String? authKey,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
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
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isPreloaded: isPreloaded ?? this.isPreloaded,
    );
  }
}
