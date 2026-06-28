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
    String? id,
    String? name,
    String? content,
  }) {
    return AppFile(
      id: id ?? this.id,
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
    return AppFile(
      id: reader.readString(),
      name: reader.readString(),
      content: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, AppFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
  }
}
