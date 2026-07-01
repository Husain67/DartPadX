import 'package:hive/hive.dart';

class CompilerPreset extends HiveObject {
  String id;
  String name;
  String endpointUrl;
  String httpMethod; // GET, POST, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  String? authToken;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate; // JSON with placeholders like {code}, {language}, {stdin}

  // Response Mapping paths (dot notation e.g., output.stdout)
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    this.authToken,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authToken,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
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
      authToken: authToken ?? this.authToken,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      endpointUrl: json['endpointUrl'] as String,
      httpMethod: json['httpMethod'] as String,
      authType: json['authType'] as String,
      authToken: json['authToken'] as String?,
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] as String,
      stdoutPath: json['stdoutPath'] as String,
      stderrPath: json['stderrPath'] as String,
      errorPath: json['errorPath'] as String,
      executionTimePath: json['executionTimePath'] as String,
      memoryPath: json['memoryPath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'authToken': authToken,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
    };
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
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      authToken: fields[5] as String?,
      headers: (fields[6] as Map).cast<String, String>(),
      queryParams: (fields[7] as Map).cast<String, String>(),
      requestBodyTemplate: fields[8] as String,
      stdoutPath: fields[9] as String,
      stderrPath: fields[10] as String,
      errorPath: fields[11] as String,
      executionTimePath: fields[12] as String,
      memoryPath: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.endpointUrl)
      ..writeByte(3)
      ..write(obj.httpMethod)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authToken)
      ..writeByte(6)
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.queryParams)
      ..writeByte(8)
      ..write(obj.requestBodyTemplate)
      ..writeByte(9)
      ..write(obj.stdoutPath)
      ..writeByte(10)
      ..write(obj.stderrPath)
      ..writeByte(11)
      ..write(obj.errorPath)
      ..writeByte(12)
      ..write(obj.executionTimePath)
      ..writeByte(13)
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
