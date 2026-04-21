import 'package:hive/hive.dart';

class CodeFile {
  final String id;
  final String name;
  final String content;
  final String language;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    this.language = 'dart',
  });

  CodeFile copyWith({
    String? id,
    String? name,
    String? content,
    String? language,
  }) {
    return CodeFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }
}

class CodeFileAdapter extends TypeAdapter<CodeFile> {
  @override
  final int typeId = 0;

  @override
  CodeFile read(BinaryReader reader) {
    return CodeFile(
      id: reader.readString(),
      name: reader.readString(),
      content: reader.readString(),
      language: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
    writer.writeString(obj.language);
  }
}
