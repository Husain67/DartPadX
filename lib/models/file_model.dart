import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'file_model.g.dart';

@HiveType(typeId: 0)
class FileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
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
