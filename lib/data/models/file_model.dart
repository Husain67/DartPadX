import 'package:hive/hive.dart';

part 'file_model.g.dart';

@HiveType(typeId: 0)
class FileModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final int lastModified;

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
    int? lastModified,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
