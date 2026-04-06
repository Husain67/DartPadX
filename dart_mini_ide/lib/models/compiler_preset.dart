import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CompilerPreset {
  final String id;
  String name;
  String endpointUrl;
  String httpMethod; // 'POST', 'GET', 'PUT'
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate; // JSON template with {code}, {stdin}, {language}

  // Response Mappings (dot notation)
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
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

  factory CompilerPreset.create({
    required String name,
    required String endpointUrl,
    String httpMethod = 'POST',
    String authType = 'None',
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String bodyTemplate = '',
    String stdoutPath = '',
    String stderrPath = '',
    String errorPath = '',
    String executionTimePath = '',
    String memoryPath = '',
  }) {
    return CompilerPreset(
      id: const Uuid().v4(),
      name: name,
      endpointUrl: endpointUrl,
      httpMethod: httpMethod,
      authType: authType,
      headers: headers ?? {},
      queryParams: queryParams ?? {},
      bodyTemplate: bodyTemplate,
      stdoutPath: stdoutPath,
      stderrPath: stderrPath,
      errorPath: errorPath,
      executionTimePath: executionTimePath,
      memoryPath: memoryPath,
    );
  }

  CompilerPreset copyWith({
    String? id, // allow changing ID for duplication
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
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
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
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
      name: json['name'] as String? ?? 'Imported Preset',
      endpointUrl: json['endpointUrl'] as String? ?? '',
      httpMethod: json['httpMethod'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
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
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      bodyTemplate: fields[7] as String,
      stdoutPath: fields[8] as String,
      stderrPath: fields[9] as String,
      errorPath: fields[10] as String,
      executionTimePath: fields[11] as String,
      memoryPath: fields[12] as String,
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
      ..write(obj.endpointUrl)
      ..writeByte(3)
      ..write(obj.httpMethod)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.bodyTemplate)
      ..writeByte(8)
      ..write(obj.stdoutPath)
      ..writeByte(9)
      ..write(obj.stderrPath)
      ..writeByte(10)
      ..write(obj.errorPath)
      ..writeByte(11)
      ..write(obj.executionTimePath)
      ..writeByte(12)
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
