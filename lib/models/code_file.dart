import 'package:hive/hive.dart';

class CodeFile {
  final String id;
  String name;
  String content;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
  });

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
    final fieldsCount = reader.readByte();
    final Map<int, dynamic> fields = {};
    for (int i = 0; i < fieldsCount; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return CodeFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.content);
  }
}
