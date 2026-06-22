import 'package:hive/hive.dart';

part 'project_file.g.dart';

@HiveType(typeId: 0)
class ProjectFile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime lastModified;

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
