import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class ResponseMapping {
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

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
      stdoutPath: json['stdoutPath'] as String? ?? '',
      stderrPath: json['stderrPath'] as String? ?? '',
      errorPath: json['errorPath'] as String? ?? '',
      executionTimePath: json['executionTimePath'] as String? ?? '',
      memoryPath: json['memoryPath'] as String? ?? '',
    );
  }
}

class CompilerPreset extends HiveObject {
  final String id;
  String platformName;
  String endpointUrl;
  String httpMethod; // POST, GET, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate;
  ResponseMapping responseMapping;
  bool isEditable; // false for predefined presets

  CompilerPreset({
    String? id,
    required this.platformName,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.requestBodyTemplate = '',
    ResponseMapping? responseMapping,
    this.isEditable = true,
  })  : id = id ?? const Uuid().v4(),
        headers = headers ?? {},
        queryParams = queryParams ?? {},
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
    bool? isEditable,
  }) {
    return CompilerPreset(
      id: id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseMapping: responseMapping ?? this.responseMapping.copyWith(),
      isEditable: isEditable ?? this.isEditable,
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
      'isEditable': isEditable,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String?,
      platformName: json['platformName'] as String? ?? 'Unnamed',
      endpointUrl: json['endpointUrl'] as String? ?? '',
      httpMethod: json['httpMethod'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] as String? ?? '',
      responseMapping: json['responseMapping'] != null
          ? ResponseMapping.fromJson(Map<String, dynamic>.from(json['responseMapping']))
          : ResponseMapping(),
      isEditable: json['isEditable'] as bool? ?? true,
    );
  }
}

class ResponseMappingAdapter extends TypeAdapter<ResponseMapping> {
  @override
  final int typeId = 2;

  @override
  ResponseMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResponseMapping(
      stdoutPath: fields[0] as String,
      stderrPath: fields[1] as String,
      errorPath: fields[2] as String,
      executionTimePath: fields[3] as String,
      memoryPath: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResponseMapping obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.stdoutPath)
      ..writeByte(1)
      ..write(obj.stderrPath)
      ..writeByte(2)
      ..write(obj.errorPath)
      ..writeByte(3)
      ..write(obj.executionTimePath)
      ..writeByte(4)
      ..write(obj.memoryPath);
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
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      requestBodyTemplate: fields[7] as String,
      responseMapping: fields[8] as ResponseMapping,
      isEditable: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.responseMapping)
      ..writeByte(9)
      ..write(obj.isEditable);
  }
}
