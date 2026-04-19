import 'package:hive/hive.dart';

class CodeFile {
  String id;
  String title;
  String content;

  CodeFile({
    required this.id,
    required this.title,
    required this.content,
  });
}

class CodeFileAdapter extends TypeAdapter<CodeFile> {
  @override
  final int typeId = 0;

  @override
  CodeFile read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final content = reader.readString();
    return CodeFile(id: id, title: title, content: content);
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
  }
}
