import 'package:hive/hive.dart';

class CompilerPreset extends HiveObject {
  String id;
  String platformName;
  String endpointUrl;
  String httpMethod;
  String authType;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate;
  String responseStdoutPath;
  String responseStderrPath;
  String responseErrorPath;
  String responseTimePath;
  String responseMemoryPath;
  bool isReadOnly;

  CompilerPreset({
    required this.id,
    required this.platformName,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    this.headers = const {},
    this.queryParams = const {},
    required this.requestBodyTemplate,
    this.responseStdoutPath = '',
    this.responseStderrPath = '',
    this.responseErrorPath = '',
    this.responseTimePath = '',
    this.responseMemoryPath = '',
    this.isReadOnly = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? platformName,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? responseStdoutPath,
    String? responseStderrPath,
    String? responseErrorPath,
    String? responseTimePath,
    String? responseMemoryPath,
    bool? isReadOnly,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseTimePath: responseTimePath ?? this.responseTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
      isReadOnly: isReadOnly ?? this.isReadOnly,
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
      headers: (fields[5] as Map?)?.cast<String, String>() ?? {},
      queryParams: (fields[6] as Map?)?.cast<String, String>() ?? {},
      requestBodyTemplate: fields[7] as String,
      responseStdoutPath: fields[8] as String,
      responseStderrPath: fields[9] as String,
      responseErrorPath: fields[10] as String,
      responseTimePath: fields[11] as String,
      responseMemoryPath: fields[12] as String,
      isReadOnly: fields[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.responseStdoutPath)
      ..writeByte(9)
      ..write(obj.responseStderrPath)
      ..writeByte(10)
      ..write(obj.responseErrorPath)
      ..writeByte(11)
      ..write(obj.responseTimePath)
      ..writeByte(12)
      ..write(obj.responseMemoryPath)
      ..writeByte(13)
      ..write(obj.isReadOnly);
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
