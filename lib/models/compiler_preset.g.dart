// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compiler_preset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      authValue: fields[5] as String?,
      headers: (fields[6] as Map).cast<String, String>(),
      queryParams: (fields[7] as Map).cast<String, String>(),
      bodyTemplate: fields[8] as String,
      responseMapping: fields[9] as ResponseMapping,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.authValue)
      ..writeByte(6)
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.queryParams)
      ..writeByte(8)
      ..write(obj.bodyTemplate)
      ..writeByte(9)
      ..write(obj.responseMapping);
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
