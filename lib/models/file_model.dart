import 'package:hive/hive.dart';

class FileModel extends HiveObject {
  String id;
  String name;
  String content;
  DateTime lastModified;

  FileModel({
    required this.id,
    required this.name,
    required this.content,
    required this.lastModified,
  });

  FileModel copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return FileModel(
      id: id ?? this.id,
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
    return FileModel(
      id: reader.readString(),
      name: reader.readString(),
      content: reader.readString(),
      lastModified: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
    writer.writeInt(obj.lastModified.millisecondsSinceEpoch);
  }
}
