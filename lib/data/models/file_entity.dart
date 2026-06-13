import 'package:hive/hive.dart';

part 'file_entity.g.dart';

@HiveType(typeId: 0)
class FileEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime lastModified;

  FileEntity({
    required this.id,
    required this.name,
    required this.content,
    required this.lastModified,
  });

  FileEntity copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return FileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
