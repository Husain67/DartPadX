class CodeFile {
  final String id;
  String name;
  String content;
  DateTime lastModified;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  CodeFile copyWith({
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return CodeFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
