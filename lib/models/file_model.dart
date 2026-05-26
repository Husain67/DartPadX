import 'package:hive/hive.dart';

part 'file_model.g.dart';

@HiveType(typeId: 0)
class FileModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  String language;

  FileModel({
    required this.id,
    required this.name,
    required this.content,
    this.language = 'dart',
  });

  FileModel copyWith({
    String? id,
    String? name,
    String? content,
    String? language,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }
}
