import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class CodeFile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String content;

  @HiveField(2)
  String language;

  CodeFile({
    required this.name,
    required this.content,
    this.language = 'dart',
  });

  CodeFile copyWith({
    String? name,
    String? content,
    String? language,
  }) {
    return CodeFile(
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
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodeFile(
      name: fields[0] as String,
      content: fields[1] as String,
      language: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
