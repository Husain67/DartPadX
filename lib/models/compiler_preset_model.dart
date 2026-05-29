import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'compiler_preset_model.g.dart';

@HiveType(typeId: 1)
class CompilerPresetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String endpointUrl;

  @HiveField(3)
  final String httpMethod;

  @HiveField(4)
  final String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'

  @HiveField(5)
  final String? authValue; // Used depending on authType

  @HiveField(6)
  final List<Map<String, String>> headers; // e.g., [{'key': 'Content-Type', 'value': 'application/json'}]

  @HiveField(7)
  final List<Map<String, String>> queryParams;

  @HiveField(8)
  final String bodyTemplate; // JSON string with placeholders {code}, {stdin}, {language}

  @HiveField(9)
  final String stdoutPath; // dot notation, e.g., 'data.output'

  @HiveField(10)
  final String stderrPath;

  @HiveField(11)
  final String errorPath;

  @HiveField(12)
  final String timePath;

  @HiveField(13)
  final String memoryPath;

  @HiveField(14)
  final bool isDefault;

  @HiveField(15)
  final bool isBuiltIn;

  CompilerPresetModel({
    String? id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authValue,
    this.headers = const [],
    this.queryParams = const [],
    this.bodyTemplate = '{}',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.timePath = '',
    this.memoryPath = '',
    this.isDefault = false,
    this.isBuiltIn = false,
  }) : id = id ?? const Uuid().v4();

  CompilerPresetModel copyWith({
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authValue,
    List<Map<String, String>>? headers,
    List<Map<String, String>>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
    bool? isDefault,
    bool? isBuiltIn,
  }) {
    return CompilerPresetModel(
      id: id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
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
      'isDefault': isDefault,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory CompilerPresetModel.fromJson(Map<String, dynamic> json) {
    return CompilerPresetModel(
      id: json['id'],
      name: json['name'],
      endpointUrl: json['endpointUrl'],
      httpMethod: json['httpMethod'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      authValue: json['authValue'],
      headers: List<Map<String, String>>.from(
          (json['headers'] as List? ?? []).map((e) => Map<String, String>.from(e))),
      queryParams: List<Map<String, String>>.from(
          (json['queryParams'] as List? ?? []).map((e) => Map<String, String>.from(e))),
      bodyTemplate: json['bodyTemplate'] ?? '{}',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      timePath: json['timePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
      isDefault: json['isDefault'] ?? false,
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }
}
