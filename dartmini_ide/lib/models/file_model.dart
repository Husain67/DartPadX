

class FileModel {
  final String name;
  String content;
  final DateTime lastSaved;

  FileModel({
    required this.name,
    required this.content,
    required this.lastSaved,
  });

  FileModel copyWith({
    String? name,
    String? content,
    DateTime? lastSaved,
  }) {
    return FileModel(
      name: name ?? this.name,
      content: content ?? this.content,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}
