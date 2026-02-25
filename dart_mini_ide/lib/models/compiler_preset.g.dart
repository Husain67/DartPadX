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
      url: fields[2] as String,
      method: fields[3] as String,
      headers: (fields[4] as Map).cast<String, String>(),
      bodyTemplate: fields[5] as String,
      queryParams: (fields[6] as Map).cast<String, String>(),
      responseMapping: (fields[7] as Map).cast<String, String>(),
      isDefault: fields[8] as bool,
      authType: fields[9] as String,
      authKey: fields[10] as String,
      authValue: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
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
      ..write(obj.headers)
      ..writeByte(5)
      ..write(obj.bodyTemplate)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.responseMapping)
      ..writeByte(8)
      ..write(obj.isDefault)
      ..writeByte(9)
      ..write(obj.authType)
      ..writeByte(10)
      ..write(obj.authKey)
      ..writeByte(11)
      ..write(obj.authValue);
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
