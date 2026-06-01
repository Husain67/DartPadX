// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      id: fields[0] as String?,
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
      isDefault: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PresetModel obj) {
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
