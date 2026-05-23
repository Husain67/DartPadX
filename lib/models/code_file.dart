import 'package:hive/hive.dart';

part 'code_file.g.dart';

@HiveType(typeId: 0)
class CodeFile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime lastModified;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    required this.lastModified,
  });

  CodeFile copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return CodeFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
