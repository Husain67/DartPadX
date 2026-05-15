// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileStateAdapter extends TypeAdapter<FileState> {
  @override
  final int typeId = 0;

  @override
  FileState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileState(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
      isReadOnly: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FileState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.isReadOnly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
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
      authKey: fields[5] as String,
      authValue: fields[6] as String,
      headers: (fields[7] as Map).cast<String, String>(),
      queryParams: (fields[8] as Map).cast<String, String>(),
      bodyTemplate: fields[9] as String,
      stdoutPath: fields[10] as String,
      stderrPath: fields[11] as String,
      errorPath: fields[12] as String,
      executionTimePath: fields[13] as String,
      memoryPath: fields[14] as String,
      isPreloaded: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.authKey)
      ..writeByte(6)
      ..write(obj.authValue)
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
      ..write(obj.memoryPath)
      ..writeByte(15)
      ..write(obj.isPreloaded);
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
