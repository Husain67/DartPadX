import 'package:hive/hive.dart';

class CodeFile {
  final String id;
  String name;
  String content;
  DateTime lastModified;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    required this.lastModified,
  });
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
      lastModified: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
    writer.writeInt(obj.lastModified.millisecondsSinceEpoch);
  }
}
