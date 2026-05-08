// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppFileAdapter extends TypeAdapter<AppFile> {
  @override
  final int typeId = 0;

  @override
  AppFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
      language: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppFile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
