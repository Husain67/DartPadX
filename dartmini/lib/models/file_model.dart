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
  final DateTime createdAt;

  FileModel({
    String? id,
    required this.name,
    this.content = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  FileModel copyWith({
    String? name,
    String? content,
  }) {
    return FileModel(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }
}
