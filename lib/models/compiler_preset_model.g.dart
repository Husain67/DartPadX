// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compiler_preset_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompilerPresetModelAdapter extends TypeAdapter<CompilerPresetModel> {
  @override
  final int typeId = 1;

  @override
  CompilerPresetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompilerPresetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      requestBodyTemplate: fields[7] as String,
      outputMappingPath: fields[8] as String,
      errorMappingPath: fields[9] as String,
      executionTimeMappingPath: fields[10] as String,
      memoryMappingPath: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPresetModel obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.requestBodyTemplate)
      ..writeByte(8)
      ..write(obj.outputMappingPath)
      ..writeByte(9)
      ..write(obj.errorMappingPath)
      ..writeByte(10)
      ..write(obj.executionTimeMappingPath)
      ..writeByte(11)
      ..write(obj.memoryMappingPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompilerPresetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
