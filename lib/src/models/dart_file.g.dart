// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dart_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DartFileAdapter extends TypeAdapter<DartFile> {
  @override
  final int typeId = 0;

  @override
  DartFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DartFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DartFile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
