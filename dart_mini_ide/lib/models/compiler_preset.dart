import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String method; // POST, GET, PUT
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate; // JSON with {code}, {language}, etc.
  final String responseStdoutPath;
  final String responseStderrPath;
  final String responseErrorPath;
  final String responseTimePath;
  final String responseMemoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '{}',
    this.responseStdoutPath = '',
    this.responseStderrPath = '',
    this.responseErrorPath = '',
    this.responseTimePath = '',
    this.responseMemoryPath = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'method': method,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'responseStdoutPath': responseStdoutPath,
      'responseStderrPath': responseStderrPath,
      'responseErrorPath': responseErrorPath,
      'responseTimePath': responseTimePath,
      'responseMemoryPath': responseMemoryPath,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      endpoint: json['endpoint'] ?? '',
      method: json['method'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] ?? '{}',
      responseStdoutPath: json['responseStdoutPath'] ?? '',
      responseStderrPath: json['responseStderrPath'] ?? '',
      responseErrorPath: json['responseErrorPath'] ?? '',
      responseTimePath: json['responseTimePath'] ?? '',
      responseMemoryPath: json['responseMemoryPath'] ?? '',
    );
  }

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? responseStdoutPath,
    String? responseStderrPath,
    String? responseErrorPath,
    String? responseTimePath,
    String? responseMemoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseTimePath: responseTimePath ?? this.responseTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
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
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      bodyTemplate: fields[7] as String,
      responseStdoutPath: fields[8] as String,
      responseStderrPath: fields[9] as String,
      responseErrorPath: fields[10] as String,
      responseTimePath: fields[11] as String,
      responseMemoryPath: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.bodyTemplate)
      ..writeByte(8)
      ..write(obj.responseStdoutPath)
      ..writeByte(9)
      ..write(obj.responseStderrPath)
      ..writeByte(10)
      ..write(obj.responseErrorPath)
      ..writeByte(11)
      ..write(obj.responseTimePath)
      ..writeByte(12)
      ..write(obj.responseMemoryPath);
  }
}
