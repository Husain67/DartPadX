import 'package:hive/hive.dart';

class ProjectFile extends HiveObject {
  String id;
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
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectFile obj) {
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
      other is ProjectFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
