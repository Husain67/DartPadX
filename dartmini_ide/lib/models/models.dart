import 'package:hive/hive.dart';

class FileModel {
  String name;
  String content;

  FileModel({required this.name, required this.content});
}

class FileModelAdapter extends TypeAdapter<FileModel> {
  @override
  final int typeId = 0;

  @override
  FileModel read(BinaryReader reader) {
    return FileModel(
      name: reader.readString(),
      content: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.content);
  }
}

class CompilerPreset {
  String id;
  String name;
  String url;
  String method;
  String authType;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'method': method,
        'authType': authType,
        'headers': headers,
        'queryParams': queryParams,
        'bodyTemplate': bodyTemplate,
        'stdoutPath': stdoutPath,
        'stderrPath': stderrPath,
        'errorPath': errorPath,
        'executionTimePath': executionTimePath,
        'memoryPath': memoryPath,
      };

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      bodyTemplate: json['bodyTemplate'] as String? ?? '',
      stdoutPath: json['stdoutPath'] as String? ?? '',
      stderrPath: json['stderrPath'] as String? ?? '',
      errorPath: json['errorPath'] as String? ?? '',
      executionTimePath: json['executionTimePath'] as String? ?? '',
      memoryPath: json['memoryPath'] as String? ?? '',
    );
  }

  CompilerPreset copyWith({
    String? name,
    String? url,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
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
    final map = reader.readMap().cast<String, dynamic>();
    return CompilerPreset.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeMap(obj.toJson());
  }
}
