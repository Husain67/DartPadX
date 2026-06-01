import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'file_model.g.dart';

@HiveType(typeId: 0)
class FileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime updatedAt;

  FileModel({
    String? id,
    required this.name,
    required this.content,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  FileModel copyWith({
    String? name,
    String? content,
    DateTime? updatedAt,
  }) {
    return FileModel(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
