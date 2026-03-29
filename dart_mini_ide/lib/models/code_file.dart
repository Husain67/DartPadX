import 'package:hive/hive.dart';

class CodeFile {
  final String id;
  String name;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
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
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
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
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }
}
