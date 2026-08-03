import 'package:hive/hive.dart';
import 'file_model.dart';
import 'preset_model.dart';

class FileModelAdapter extends TypeAdapter<FileModel> {
  @override
  final int typeId = 0;

  @override
  FileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileModel(
      name: fields[0] as String,
      content: fields[1] as String,
      lastSaved: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.lastSaved);
  }
}

class PresetModelAdapter extends TypeAdapter<PresetModel> {
  @override
  final int typeId = 1;

  @override
  PresetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PresetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      endpoint: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      authValue: fields[5] as String? ?? '',
      authKey: fields[6] as String? ?? '',
      headers: (fields[7] as Map?)?.cast<String, String>() ?? {},
      queryParams: (fields[8] as Map?)?.cast<String, String>() ?? {},
      bodyTemplate: fields[9] as String,
      stdoutPath: fields[10] as String,
      stderrPath: fields[11] as String,
      errorPath: fields[12] as String,
      executionTimePath: fields[13] as String,
      memoryPath: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PresetModel obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.authValue)
      ..writeByte(6)
      ..write(obj.authKey)
      ..writeByte(7)
      ..write(obj.headers)
      ..writeByte(8)
      ..write(obj.queryParams)
      ..writeByte(9)
      ..write(obj.bodyTemplate)
      ..writeByte(10)
      ..write(obj.stdoutPath)
      ..writeByte(11)
      ..write(obj.stderrPath)
      ..writeByte(12)
      ..write(obj.errorPath)
      ..writeByte(13)
      ..write(obj.executionTimePath)
      ..writeByte(14)
      ..write(obj.memoryPath);
  }
}
