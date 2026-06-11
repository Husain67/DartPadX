import 'package:hive/hive.dart';

class FileModel extends HiveObject {
  String id;
  String name;
  String content;

  FileModel({
    required this.id,
    required this.name,
    required this.content,
  });

  FileModel copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
    );
  }
}

class FileModelAdapter extends TypeAdapter<FileModel> {
  @override
  final int typeId = 0;

  @override
  FileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileModel(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content);
  }
}
