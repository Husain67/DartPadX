import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  String platformName;
  String endpointUrl;
  String httpMethod; // 'POST', 'GET', 'PUT'
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'
  String authKey;
  String authValue;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate; // JSON string with placeholders {code}, {stdin}, {language}
  String defaultLanguage;

  // Response Mapping paths (dot notation)
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.platformName,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authKey = '',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '',
    this.defaultLanguage = 'dart',
    this.stdoutPath = 'stdout',
    this.stderrPath = 'stderr',
    this.errorPath = 'error',
    this.executionTimePath = 'time',
    this.memoryPath = 'memory',
  });

  CompilerPreset copyWith({
    String? id,
    String? platformName,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authKey,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? defaultLanguage,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompilerPreset(
      id: fields[0] as String,
      platformName: fields[1] as String,
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      authKey: fields[5] as String,
      authValue: fields[6] as String,
      headers: (fields[7] as Map?)?.cast<String, String>() ?? {},
      queryParams: (fields[8] as Map?)?.cast<String, String>() ?? {},
      requestBodyTemplate: fields[9] as String,
      defaultLanguage: fields[10] as String,
      stdoutPath: fields[11] as String,
      stderrPath: fields[12] as String,
      errorPath: fields[13] as String,
      executionTimePath: fields[14] as String,
      memoryPath: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.platformName)
      ..writeByte(2)
      ..write(obj.endpointUrl)
      ..writeByte(3)
      ..write(obj.httpMethod)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authKey)
      ..writeByte(6)
      ..write(obj.authValue)
      ..writeByte(7)
      ..write(obj.headers)
      ..writeByte(8)
      ..write(obj.queryParams)
      ..writeByte(9)
      ..write(obj.requestBodyTemplate)
      ..writeByte(10)
      ..write(obj.defaultLanguage)
      ..writeByte(11)
      ..write(obj.stdoutPath)
      ..writeByte(12)
      ..write(obj.stderrPath)
      ..writeByte(13)
      ..write(obj.errorPath)
      ..writeByte(14)
      ..write(obj.executionTimePath)
      ..writeByte(15)
      ..write(obj.memoryPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompilerPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
