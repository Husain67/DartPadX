// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodeFileAdapter extends TypeAdapter<CodeFile> {
  @override
  final int typeId = 0;

  @override
  CodeFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodeFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
      language: fields[3] as String,
      lastModified: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
