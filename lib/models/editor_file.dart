import 'package:uuid/uuid.dart';

class EditorFile {
  final String id;
  String name;
  String content;
  bool isSaved;

  EditorFile({
    String? id,
    required this.name,
    this.content = '',
    this.isSaved = true,
  }) : id = id ?? const Uuid().v4();

  EditorFile copyWith({
    String? name,
    String? content,
    bool? isSaved,
  }) {
    return EditorFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'isSaved': isSaved,
    };
  }

  factory EditorFile.fromMap(Map<String, dynamic> map) {
    return EditorFile(
      id: map['id'] as String,
      name: map['name'] as String,
      content: map['content'] as String,
      isSaved: map['isSaved'] as bool,
    );
  }
}
