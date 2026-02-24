import 'package:hive/hive.dart';

part 'code_file.g.dart';

@HiveType(typeId: 0)
class CodeFile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime lastModified;

  CodeFile({
    required this.name,
    required this.content,
    required this.lastModified,
  });
}
