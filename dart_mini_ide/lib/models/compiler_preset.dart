import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class ResponseMapping {
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;

  ResponseMapping({
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
  });

  ResponseMapping copyWith({
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    return ResponseMapping(
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
    };
  }

  factory ResponseMapping.fromJson(Map<String, dynamic> json) {
    return ResponseMapping(
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      executionTimePath: json['executionTimePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
    );
  }
}

class CompilerPreset {
  final String id;
  String platformName;
  String endpointUrl;
  String httpMethod; // GET, POST, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate; // JSON with {code}, {language}, {stdin}
  ResponseMapping responseMapping;

  CompilerPreset({
    String? id,
    required this.platformName,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '{}',
    ResponseMapping? responseMapping,
  })  : id = id ?? const Uuid().v4(),
        responseMapping = responseMapping ?? ResponseMapping();

  CompilerPreset copyWith({
    String? platformName,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    ResponseMapping? responseMapping,
  }) {
    return CompilerPreset(
      id: id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseMapping: responseMapping ?? this.responseMapping,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platformName': platformName,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'responseMapping': responseMapping.toJson(),
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      platformName: json['platformName'] ?? 'Unknown',
      endpointUrl: json['endpointUrl'] ?? '',
      httpMethod: json['httpMethod'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] ?? '{}',
      responseMapping: json['responseMapping'] != null ? ResponseMapping.fromJson(json['responseMapping']) : null,
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

    // Read ResponseMapping
    final rmFields = fields[8] as Map<dynamic, dynamic>? ?? {};
    final responseMapping = ResponseMapping(
      stdoutPath: rmFields['stdoutPath'] as String? ?? '',
      stderrPath: rmFields['stderrPath'] as String? ?? '',
      errorPath: rmFields['errorPath'] as String? ?? '',
      executionTimePath: rmFields['executionTimePath'] as String? ?? '',
      memoryPath: rmFields['memoryPath'] as String? ?? '',
    );

    return CompilerPreset(
      id: fields[0] as String?,
      platformName: fields[1] as String,
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      requestBodyTemplate: fields[7] as String,
      responseMapping: responseMapping,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.requestBodyTemplate)
      ..writeByte(8)
      ..write({
        'stdoutPath': obj.responseMapping.stdoutPath,
        'stderrPath': obj.responseMapping.stderrPath,
        'errorPath': obj.responseMapping.errorPath,
        'executionTimePath': obj.responseMapping.executionTimePath,
        'memoryPath': obj.responseMapping.memoryPath,
      });
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
