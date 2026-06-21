import 'package:hive/hive.dart';

class ProjectFile extends HiveObject {
  String id;
  String name;
  String content;
  DateTime lastModified;

  ProjectFile({
    required this.id,
    required this.name,
    required this.content,
    required this.lastModified,
  });

  ProjectFile copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return ProjectFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

class ProjectFileAdapter extends TypeAdapter<ProjectFile> {
  @override
  final int typeId = 0;

  @override
  ProjectFile read(BinaryReader reader) {
    return ProjectFile(
      id: reader.readString(),
      name: reader.readString(),
      content: reader.readString(),
      lastModified: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
    writer.writeString(obj.lastModified.toIso8601String());
  }
}
