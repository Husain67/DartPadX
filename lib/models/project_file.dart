import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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

  factory ProjectFile.create({String? name, String? content}) {
    return ProjectFile(
      id: const Uuid().v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
      lastModified: DateTime.now(),
    );
  }

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
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
      lastModified: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectFile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.lastModified);
  }
}
