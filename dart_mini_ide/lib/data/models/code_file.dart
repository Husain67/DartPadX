import 'package:hive/hive.dart';

part 'code_file.g.dart';

@HiveType(typeId: 0)
class CodeFile {
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
}
