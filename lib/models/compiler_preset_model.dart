import 'package:hive/hive.dart';

part 'compiler_preset_model.g.dart';

@HiveType(typeId: 1)
class CompilerPresetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String method; // GET, POST, PUT

  @HiveField(4)
  String authType; // None, Header API Key, Bearer Token, Query Param

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String requestBodyTemplate; // JSON with placeholders like {code}, {stdin}

  @HiveField(8)
  String outputMappingPath; // dot notation, e.g., output.stdout

  @HiveField(9)
  String errorMappingPath; // dot notation

  @HiveField(10)
  String executionTimeMappingPath;

  @HiveField(11)
  String memoryMappingPath;

  CompilerPresetModel({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.outputMappingPath,
    required this.errorMappingPath,
    required this.executionTimeMappingPath,
    required this.memoryMappingPath,
  });

  CompilerPresetModel copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? outputMappingPath,
    String? errorMappingPath,
    String? executionTimeMappingPath,
    String? memoryMappingPath,
  }) {
    return CompilerPresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      outputMappingPath: outputMappingPath ?? this.outputMappingPath,
      errorMappingPath: errorMappingPath ?? this.errorMappingPath,
      executionTimeMappingPath: executionTimeMappingPath ?? this.executionTimeMappingPath,
      memoryMappingPath: memoryMappingPath ?? this.memoryMappingPath,
    );
  }
}
