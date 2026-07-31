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
  String language;

  CodeFile({
    required this.id,
    required this.name,
    this.content = '',
    this.language = 'dart',
  });

  CodeFile copyWith({
    String? id,
    String? name,
    String? content,
    String? language,
  }) {
    return CodeFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }
}
