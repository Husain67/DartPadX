import 'package:hive/hive.dart';

part 'editor_file.g.dart';

@HiveType(typeId: 0)
class EditorFile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String content;

  EditorFile({
    required this.id,
    required this.name,
    required this.content,
  });

  EditorFile copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return EditorFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
    );
  }
}
