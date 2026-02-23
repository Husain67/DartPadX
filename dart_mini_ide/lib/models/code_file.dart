import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'code_file.g.dart';

@HiveType(typeId: 0)
class CodeFile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  String language;

  @HiveField(4)
  DateTime lastModified;

  CodeFile({
    String? id,
    required this.name,
    required this.content,
    this.language = 'dart',
    DateTime? lastModified,
  })  : id = id ?? const Uuid().v4(),
        lastModified = lastModified ?? DateTime.now();

  CodeFile copyWith({
    String? name,
    String? content,
    String? language,
    DateTime? lastModified,
  }) {
    return CodeFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
