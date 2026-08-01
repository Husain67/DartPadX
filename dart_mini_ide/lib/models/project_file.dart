import 'package:hive/hive.dart';

class ProjectFile {
  final String id;
  String name;
  String content;

  ProjectFile({
    required this.id,
    required this.name,
    required this.content,
  });

  ProjectFile copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return ProjectFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
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
    );
  }

  @override
  void write(BinaryWriter writer, ProjectFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
  }
}
