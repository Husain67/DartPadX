import 'package:hive/hive.dart';

class CompilerPreset extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String endpoint;
  @HiveField(2)
  String method;
  @HiveField(3)
  String authType;
  @HiveField(4)
  Map<String, String> headers;
  @HiveField(5)
  Map<String, String> queryParams;
  @HiveField(6)
  String bodyTemplate;
  @HiveField(7)
  Map<String, String> responseMapping;

  CompilerPreset({
    required this.name,
    required this.endpoint,
    required this.method,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.responseMapping,
  });
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
      name: fields[0] as String,
      endpoint: fields[1] as String,
      method: fields[2] as String,
      authType: fields[3] as String,
      headers: (fields[4] as Map).cast<String, String>(),
      queryParams: (fields[5] as Map).cast<String, String>(),
      bodyTemplate: fields[6] as String,
      responseMapping: (fields[7] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.authType)
      ..writeByte(4)
      ..write(obj.headers)
      ..writeByte(5)
      ..write(obj.queryParams)
      ..writeByte(6)
      ..write(obj.bodyTemplate)
      ..writeByte(7)
      ..write(obj.responseMapping);
  }
}
