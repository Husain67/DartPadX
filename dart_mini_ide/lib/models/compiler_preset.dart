import 'package:hive/hive.dart';

class CompilerPreset extends HiveObject {
  final String id;
  String name;
  String url;
  String method;
  String authType;
  String authValue;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String timePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.timePath,
    required this.memoryPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'method': method,
      'authType': authType,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
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
      name: json['name'] as String,
      url: json['url'] as String,
      method: json['method'] as String,
      authType: json['authType'] as String,
      authValue: json['authValue'] as String,
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] as String,
      stdoutPath: json['stdoutPath'] as String,
      stderrPath: json['stderrPath'] as String,
      errorPath: json['errorPath'] as String,
      timePath: json['timePath'] as String,
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
      url: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      authValue: fields[5] as String,
      headers: (fields[6] as Map).cast<String, String>(),
      queryParams: (fields[7] as Map).cast<String, String>(),
      bodyTemplate: fields[8] as String,
      stdoutPath: fields[9] as String,
      stderrPath: fields[10] as String,
      errorPath: fields[11] as String,
      timePath: fields[12] as String,
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
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authValue)
      ..writeByte(6)
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.queryParams)
      ..writeByte(8)
      ..write(obj.bodyTemplate)
      ..writeByte(9)
      ..write(obj.stdoutPath)
      ..writeByte(10)
      ..write(obj.stderrPath)
      ..writeByte(11)
      ..write(obj.errorPath)
      ..writeByte(12)
      ..write(obj.timePath)
      ..writeByte(13)
      ..write(obj.memoryPath);
  }
}
