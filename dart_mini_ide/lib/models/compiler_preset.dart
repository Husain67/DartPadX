import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String url;
  final String method;
  final String authType;
  final String authValue;
  final List<MapEntry<String, String>> headers;
  final List<MapEntry<String, String>> queryParams;
  final String bodyTemplate;
  final Map<String, String> responseMappings;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.responseMappings,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    String? authValue,
    List<MapEntry<String, String>>? headers,
    List<MapEntry<String, String>>? queryParams,
    String? bodyTemplate,
    Map<String, String>? responseMappings,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseMappings: responseMappings ?? this.responseMappings,
    );
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final url = reader.readString();
    final method = reader.readString();
    final authType = reader.readString();
    final authValue = reader.readString();

    final headerCount = reader.readInt();
    final headers = <MapEntry<String, String>>[];
    for (int i = 0; i < headerCount; i++) {
      headers.add(MapEntry(reader.readString(), reader.readString()));
    }

    final queryCount = reader.readInt();
    final queryParams = <MapEntry<String, String>>[];
    for (int i = 0; i < queryCount; i++) {
      queryParams.add(MapEntry(reader.readString(), reader.readString()));
    }

    final bodyTemplate = reader.readString();

    final mappingCount = reader.readInt();
    final responseMappings = <String, String>{};
    for (int i = 0; i < mappingCount; i++) {
      responseMappings[reader.readString()] = reader.readString();
    }

    return CompilerPreset(
      id: id,
      name: name,
      url: url,
      method: method,
      authType: authType,
      authValue: authValue,
      headers: headers,
      queryParams: queryParams,
      bodyTemplate: bodyTemplate,
      responseMappings: responseMappings,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.url);
    writer.writeString(obj.method);
    writer.writeString(obj.authType);
    writer.writeString(obj.authValue);

    writer.writeInt(obj.headers.length);
    for (final header in obj.headers) {
      writer.writeString(header.key);
      writer.writeString(header.value);
    }

    writer.writeInt(obj.queryParams.length);
    for (final param in obj.queryParams) {
      writer.writeString(param.key);
      writer.writeString(param.value);
    }

    writer.writeString(obj.bodyTemplate);

    writer.writeInt(obj.responseMappings.length);
    obj.responseMappings.forEach((key, value) {
      writer.writeString(key);
      writer.writeString(value);
    });
  }
}
