import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'preset_model.g.dart';

@HiveType(typeId: 1)
class PresetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String endpointUrl;

  @HiveField(3)
  final String httpMethod; // GET, POST, PUT

  @HiveField(4)
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  final Map<String, String> headers;

  @HiveField(6)
  final Map<String, String> queryParams;

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

  PresetModel({
    String? id,
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
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  PresetModel copyWith({
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
    bool? isDefault,
  }) {
    return PresetModel(
      id: id,
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
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory PresetModel.fromJson(Map<String, dynamic> json) {
    return PresetModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      endpointUrl: json['endpointUrl'] as String,
      httpMethod: json['httpMethod'] as String,
      authType: json['authType'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      queryParams: Map<String, String>.from(json['queryParams'] as Map),
      requestBodyTemplate: json['requestBodyTemplate'] as String,
      stdoutPath: json['stdoutPath'] as String,
      stderrPath: json['stderrPath'] as String,
      errorPath: json['errorPath'] as String,
      executionTimePath: json['executionTimePath'] as String,
      memoryPath: json['memoryPath'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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
      'isDefault': isDefault,
    };
  }
}
