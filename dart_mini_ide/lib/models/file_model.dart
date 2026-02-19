import 'package:hive/hive.dart';

class FileModel extends HiveObject {
  String name;
  String content;
  DateTime lastModified;

  FileModel({
    required this.name,
    required this.content,
    required this.lastModified,
  });
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
      name: fields[0] as String,
      content: fields[1] as String,
      lastModified: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.lastModified);
  }
}
