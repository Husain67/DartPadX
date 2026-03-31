import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CodeFile extends HiveObject {
  String id;
  String name;
  String content;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
  });

  factory CodeFile.create({
    required String name,
    required String content,
  }) {
    return CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
  }
}

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
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content);
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
