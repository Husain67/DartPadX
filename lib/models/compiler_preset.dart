import 'package:hive/hive.dart';

class CompilerPreset extends HiveObject {
  String id;
  String name;
  String endpointUrl;
  String httpMethod;
  String authType;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;
  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
    this.isDefault = false,
  });

  CompilerPreset copyWith({
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
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
      requestBodyTemplate: fields[7] as String,
      stdoutPath: fields[8] as String,
      stderrPath: fields[9] as String,
      errorPath: fields[10] as String,
      executionTimePath: fields[11] as String,
      memoryPath: fields[12] as String,
      isDefault: fields[13] as bool? ?? false,
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
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.requestBodyTemplate)
      ..writeByte(8)
      ..write(obj.stdoutPath)
      ..writeByte(9)
      ..write(obj.stderrPath)
      ..writeByte(10)
      ..write(obj.errorPath)
      ..writeByte(11)
      ..write(obj.executionTimePath)
      ..writeByte(12)
      ..write(obj.memoryPath)
      ..writeByte(13)
      ..write(obj.isDefault);
  }
}
