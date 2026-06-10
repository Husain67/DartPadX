import 'package:hive/hive.dart';

class DartFile extends HiveObject {
  String id;
  String name;
  String content;

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
}

class DartFileAdapter extends TypeAdapter<DartFile> {
  @override
  final int typeId = 0;

  @override
  DartFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DartFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DartFile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
