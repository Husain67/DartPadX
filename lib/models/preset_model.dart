import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class PresetModel extends HiveObject {
  String id;
  String name;
  String url;
  String method;
  String authType;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  Map<String, String> responseMappings;

  PresetModel({
    String? id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.responseMappings = const {},
  }) : id = id ?? const Uuid().v4();

  PresetModel copyWith({
    String? name,
    String? url,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    Map<String, String>? responseMappings,
  }) {
    return PresetModel(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseMappings: responseMappings ?? Map.from(this.responseMappings),
    );
  }
}

class PresetModelAdapter extends TypeAdapter<PresetModel> {
  @override
  final int typeId = 1;

  @override
  PresetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PresetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      bodyTemplate: fields[7] as String,
      responseMappings: (fields[8] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PresetModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.bodyTemplate)
      ..writeByte(8)
      ..write(obj.responseMappings);
  }
}
