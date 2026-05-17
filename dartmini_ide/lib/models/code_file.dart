import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'code_file.g.dart';

@HiveType(typeId: 0)
class CodeFile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  CodeFile({
    String? id,
    required this.name,
    required this.content,
  }) : id = id ?? const Uuid().v4();

  CodeFile copyWith({String? name, String? content}) {
    return CodeFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
    );
  }
}
