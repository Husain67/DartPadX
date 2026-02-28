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
  bool isSaved;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    this.isSaved = true,
  });
}
