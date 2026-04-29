import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String httpMethod; // GET, POST, PUT
  final String authType; // None, Header, Bearer, Basic, Query
  final String authValue;
  final List<MapEntry<String, String>> headers;
  final List<MapEntry<String, String>> queryParams;
  final String bodyTemplate;

  // Response Mapping paths
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String timePath;
  final String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.headers = const [],
    this.queryParams = const [],
    this.bodyTemplate = '{"content": "{code}"}',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.timePath = '',
    this.memoryPath = '',
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? httpMethod,
    String? authType,
    String? authValue,
    List<MapEntry<String, String>>? headers,
    List<MapEntry<String, String>>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
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
    final endpoint = reader.readString();
    final httpMethod = reader.readString();
    final authType = reader.readString();
    final authValue = reader.readString();

    final headerLen = reader.readInt();
    final headers = <MapEntry<String, String>>[];
    for (var i = 0; i < headerLen; i++) {
      headers.add(MapEntry(reader.readString(), reader.readString()));
    }

    final queryLen = reader.readInt();
    final queryParams = <MapEntry<String, String>>[];
    for (var i = 0; i < queryLen; i++) {
      queryParams.add(MapEntry(reader.readString(), reader.readString()));
    }

    final bodyTemplate = reader.readString();
    final stdoutPath = reader.readString();
    final stderrPath = reader.readString();
    final errorPath = reader.readString();
    final timePath = reader.readString();
    final memoryPath = reader.readString();

    return CompilerPreset(
      id: id,
      name: name,
      endpoint: endpoint,
      httpMethod: httpMethod,
      authType: authType,
      authValue: authValue,
      headers: headers,
      queryParams: queryParams,
      bodyTemplate: bodyTemplate,
      stdoutPath: stdoutPath,
      stderrPath: stderrPath,
      errorPath: errorPath,
      timePath: timePath,
      memoryPath: memoryPath,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.endpoint);
    writer.writeString(obj.httpMethod);
    writer.writeString(obj.authType);
    writer.writeString(obj.authValue);

    writer.writeInt(obj.headers.length);
    for (var entry in obj.headers) {
      writer.writeString(entry.key);
      writer.writeString(entry.value);
    }

    writer.writeInt(obj.queryParams.length);
    for (var entry in obj.queryParams) {
      writer.writeString(entry.key);
      writer.writeString(entry.value);
    }

    writer.writeString(obj.bodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.timePath);
    writer.writeString(obj.memoryPath);
  }
}
