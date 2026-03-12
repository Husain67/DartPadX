import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CodeFile {
  final String id;
  String name;
  String content;

  CodeFile({
    String? id,
    required this.name,
    required this.content,
  }) : id = id ?? const Uuid().v4();

  CodeFile copyWith({
    String? id,
    String? name,
    String? content,
  }) {
    return CodeFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
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
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
  }
}
