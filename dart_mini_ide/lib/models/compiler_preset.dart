import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  final String platformName;
  final String endpointUrl;
  final String httpMethod;
  final String authType;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String requestBodyTemplate;
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String timePath;
  final String memoryPath;

  CompilerPreset({
    required this.id,
    required this.platformName,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.timePath,
    required this.memoryPath,
  });

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
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'timePath': timePath,
      'memoryPath': memoryPath,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      platformName: json['platformName'] as String,
      endpointUrl: json['endpointUrl'] as String,
      httpMethod: json['httpMethod'] as String,
      authType: json['authType'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      queryParams: Map<String, String>.from(json['queryParams'] as Map),
      requestBodyTemplate: json['requestBodyTemplate'] as String,
      stdoutPath: json['stdoutPath'] as String,
      stderrPath: json['stderrPath'] as String,
      errorPath: json['errorPath'] as String,
      timePath: json['timePath'] as String,
      memoryPath: json['memoryPath'] as String,
    );
  }

  CompilerPreset copyWith({
    String? id,
    String? platformName,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
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
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
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
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      requestBodyTemplate: fields[7] as String,
      stdoutPath: fields[8] as String,
      stderrPath: fields[9] as String,
      errorPath: fields[10] as String,
      timePath: fields[11] as String,
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
      ..write(obj.stdoutPath)
      ..writeByte(9)
      ..write(obj.stderrPath)
      ..writeByte(10)
      ..write(obj.errorPath)
      ..writeByte(11)
      ..write(obj.timePath)
      ..writeByte(12)
      ..write(obj.memoryPath);
  }
}
