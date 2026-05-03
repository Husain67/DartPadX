import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String endpointUrl;
  final String httpMethod;
  final String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'
  final String authKey; // e.g. 'Authorization', 'x-api-key', or query param name
  final String authValue;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate;

  // Response Mapping paths
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
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
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
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
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
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
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      endpointUrl: json['endpointUrl'] as String? ?? '',
      httpMethod: json['httpMethod'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      authKey: json['authKey'] as String? ?? '',
      authValue: json['authValue'] as String? ?? '',
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      bodyTemplate: json['bodyTemplate'] as String? ?? '',
      stdoutPath: json['stdoutPath'] as String? ?? '',
      stderrPath: json['stderrPath'] as String? ?? '',
      errorPath: json['errorPath'] as String? ?? '',
      executionTimePath: json['executionTimePath'] as String? ?? '',
      memoryPath: json['memoryPath'] as String? ?? '',
    );
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    return CompilerPreset.fromJson(
      Map<String, dynamic>.from(jsonDecode(reader.readString())),
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
