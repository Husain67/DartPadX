import 'package:hive/hive.dart';

part 'dart_file.g.dart'; // We will create this manually to avoid generator issues

@HiveType(typeId: 0)
class DartFile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime updatedAt;

  DartFile({
    required this.id,
    required this.name,
    required this.content,
    required this.updatedAt,
  });

  DartFile copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? updatedAt,
  }) {
    return DartFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
