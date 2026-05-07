import 'package:uuid/uuid.dart';

class AppFile {
  final String id;
  final String name;
  final String content;

  AppFile({
    String? id,
    required this.name,
    required this.content,
  }) : id = id ?? const Uuid().v4();

  AppFile copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return AppFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
    };
  }

  factory AppFile.fromMap(Map<dynamic, dynamic> map) {
    return AppFile(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'untitled.dart',
      content: map['content']?.toString() ?? '',
    );
  }
}
