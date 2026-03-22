import 'package:hive/hive.dart';

class CompilerPreset {
  String id;
  String name;
  String url;
  String method; // GET, POST, PUT
  String authType; // None, Header, Bearer, Basic, Query
  List<Map<String, String>> headers; // e.g. [{"key": "x-api-key", "value": "123"}]
  List<Map<String, String>> queryParams;
  String bodyTemplate; // JSON string with {code}, {language}, {stdin}

  // Response Mapping paths (dot notation)
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

  Map<String, dynamic> toJson() {
    return {
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
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      method: json['method'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      headers: (json['headers'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      queryParams: (json['queryParams'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      bodyTemplate: json['bodyTemplate'] ?? '',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      executionTimePath: json['executionTimePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
    );
  }

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    List<Map<String, String>>? headers,
    List<Map<String, String>>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? List.from(this.headers.map((e) => Map<String, String>.from(e))),
      queryParams: queryParams ?? List.from(this.queryParams.map((e) => Map<String, String>.from(e))),
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
    return CompilerPreset(
      id: reader.readString(),
      name: reader.readString(),
      url: reader.readString(),
      method: reader.readString(),
      authType: reader.readString(),
      headers: (reader.readList()).map((e) => Map<String, String>.from(e)).toList(),
      queryParams: (reader.readList()).map((e) => Map<String, String>.from(e)).toList(),
      bodyTemplate: reader.readString(),
      stdoutPath: reader.readString(),
      stderrPath: reader.readString(),
      errorPath: reader.readString(),
      executionTimePath: reader.readString(),
      memoryPath: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.url);
    writer.writeString(obj.method);
    writer.writeString(obj.authType);
    writer.writeList(obj.headers);
    writer.writeList(obj.queryParams);
    writer.writeString(obj.bodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.executionTimePath);
    writer.writeString(obj.memoryPath);
  }
}
