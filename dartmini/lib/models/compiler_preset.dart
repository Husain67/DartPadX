import 'package:hive/hive.dart';

class CompilerPreset extends HiveObject {
  String id;
  String name;
  String endpointUrl;
  String httpMethod; // POST, GET, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '{}',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
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
    final endpointUrl = reader.readString();
    final httpMethod = reader.readString();
    final authType = reader.readString();
    final headers = Map<String, String>.from(reader.readMap());
    final queryParams = Map<String, String>.from(reader.readMap());
    final requestBodyTemplate = reader.readString();
    final stdoutPath = reader.readString();
    final stderrPath = reader.readString();
    final errorPath = reader.readString();
    final executionTimePath = reader.readString();
    final memoryPath = reader.readString();

    return CompilerPreset(
      id: id,
      name: name,
      endpointUrl: endpointUrl,
      httpMethod: httpMethod,
      authType: authType,
      headers: headers,
      queryParams: queryParams,
      requestBodyTemplate: requestBodyTemplate,
      stdoutPath: stdoutPath,
      stderrPath: stderrPath,
      errorPath: errorPath,
      executionTimePath: executionTimePath,
      memoryPath: memoryPath,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.endpointUrl);
    writer.writeString(obj.httpMethod);
    writer.writeString(obj.authType);
    writer.writeMap(obj.headers);
    writer.writeMap(obj.queryParams);
    writer.writeString(obj.requestBodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.executionTimePath);
    writer.writeString(obj.memoryPath);
  }
}
