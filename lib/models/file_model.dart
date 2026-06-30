import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class FileModel extends HiveObject {
  String id;
  String name;
  String content;
  DateTime lastModified;

  FileModel({
    String? id,
    required this.name,
    required this.content,
    DateTime? lastModified,
  })  : id = id ?? const Uuid().v4(),
        lastModified = lastModified ?? DateTime.now();

  FileModel copyWith({
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return FileModel(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
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
      lastModified: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.lastModified.millisecondsSinceEpoch);
  }
}
