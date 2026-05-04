class DartFile {
  final String id;
  final String name;
  final String content;

  DartFile({
    required this.id,
    required this.name,
    required this.content,
  });

  DartFile copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return DartFile(
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

  factory DartFile.fromMap(Map<String, dynamic> map) {
    return DartFile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      content: map['content'] ?? '',
    );
  }
}
