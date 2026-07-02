import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class AppFile extends HiveObject {
  final String id;
  String name;
  String content;

  AppFile({
    String? id,
    required this.name,
    this.content = '',
  }) : id = id ?? const Uuid().v4();

  AppFile copyWith({
    String? name,
    String? content,
  }) {
    return AppFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
    );
  }
}

class AppFileAdapter extends TypeAdapter<AppFile> {
  @override
  final int typeId = 0;

  @override
  AppFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppFile(
      id: fields[0] as String,
      name: fields[1] as String,
      content: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppFile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content);
  }
}
