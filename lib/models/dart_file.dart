import 'package:hive/hive.dart'; // We will use manual adapter

class DartFile {
  String id;
  String name;
  String content;
  DateTime lastModified;

  DartFile({
    required this.id,
    required this.name,
    required this.content,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory DartFile.fromJson(Map<String, dynamic> json) {
    return DartFile(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }
}

class DartFileAdapter extends TypeAdapter<DartFile> {
  @override
  final int typeId = 0;

  @override
  DartFile read(BinaryReader reader) {
    return DartFile(
      id: reader.readString(),
      name: reader.readString(),
      content: reader.readString(),
      lastModified: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, DartFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
    writer.writeString(obj.lastModified.toIso8601String());
  }
}
