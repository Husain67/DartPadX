import 'package:uuid/uuid.dart';

class FileModel {
  final String id;
  final String name;
  final String content;

  FileModel({
    String? id,
    required this.name,
    required this.content,
  }) : id = id ?? const Uuid().v4();

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
    };
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      name: json['name'],
      content: json['content'],
    );
  }
}
