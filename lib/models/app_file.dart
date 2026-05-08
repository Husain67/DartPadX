import 'package:hive/hive.dart';

part 'app_file.g.dart';

@HiveType(typeId: 0)
class AppFile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  final String language;

  AppFile({
    required this.id,
    required this.name,
    required this.content,
    this.language = 'dart',
  });

  AppFile copyWith({
    String? id,
    String? name,
    String? content,
    String? language,
  }) {
    return AppFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }
}
