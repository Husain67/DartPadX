import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  String name;
  String endpoint;
  String method;
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  String? authKey;
  String? authValue;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.method,
    required this.authType,
    this.authKey,
    this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
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
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      authType: json['authType'] as String,
      authKey: json['authKey'] as String?,
      authValue: json['authValue'] as String?,
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      bodyTemplate: json['bodyTemplate'] as String,
      stdoutPath: json['stdoutPath'] as String,
      stderrPath: json['stderrPath'] as String,
      errorPath: json['errorPath'] as String,
      executionTimePath: json['executionTimePath'] as String,
      memoryPath: json['memoryPath'] as String,
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
      name: fields[1] as String,
      endpoint: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      authKey: fields[5] as String?,
      authValue: fields[6] as String?,
      headers: (fields[7] as Map).cast<String, String>(),
      queryParams: (fields[8] as Map).cast<String, String>(),
      bodyTemplate: fields[9] as String,
      stdoutPath: fields[10] as String,
      stderrPath: fields[11] as String,
      errorPath: fields[12] as String,
      executionTimePath: fields[13] as String,
      memoryPath: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.endpoint)
      ..writeByte(3)
      ..write(obj.method)
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
      ..write(obj.bodyTemplate)
      ..writeByte(10)
      ..write(obj.stdoutPath)
      ..writeByte(11)
      ..write(obj.stderrPath)
      ..writeByte(12)
      ..write(obj.errorPath)
      ..writeByte(13)
      ..write(obj.executionTimePath)
      ..writeByte(14)
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
