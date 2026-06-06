import 'dart:convert';

class FileModel {
  final String id;
  final String name;
  final String content;

  FileModel({
    required this.id,
    required this.name,
    required this.content,
  });

  FileModel copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return FileModel(
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

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      content: map['content'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FileModel.fromJson(String source) =>
      FileModel.fromMap(json.decode(source));
}
