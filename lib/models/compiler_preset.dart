import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CompilerPreset {
  final String id;
  String name;
  String url;
  String method;
  String authType;
  String? authValue;
  List<MapEntry<String, String>> headers;
  List<MapEntry<String, String>> queryParams;
  String bodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    String? id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.authValue,
    List<MapEntry<String, String>>? headers,
    List<MapEntry<String, String>>? queryParams,
    this.bodyTemplate = '{"content": "{code}"}',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
  })  : id = id ?? const Uuid().v4(),
        headers = headers ?? [],
        queryParams = queryParams ?? [];

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
      authValue: authValue ?? this.authValue,
      headers: headers ?? List.from(this.headers),
      queryParams: queryParams ?? List.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'method': method,
      'authType': authType,
      'authValue': authValue,
      'headers': headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'queryParams': queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
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
      authValue: json['authValue'],
      headers: (json['headers'] as List?)
              ?.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String))
              .toList() ??
          [],
      queryParams: (json['queryParams'] as List?)
              ?.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String))
              .toList() ??
          [],
      bodyTemplate: json['bodyTemplate'] ?? '{"content": "{code}"}',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      executionTimePath: json['executionTimePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
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
      authValue: reader.readString(),
      headers: reader.readList().map((e) {
        final pair = e as List;
        return MapEntry<String, String>(pair[0] as String, pair[1] as String);
      }).toList(),
      queryParams: reader.readList().map((e) {
        final pair = e as List;
        return MapEntry<String, String>(pair[0] as String, pair[1] as String);
      }).toList(),
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
    writer.writeString(obj.authValue ?? '');
    writer.writeList(obj.headers.map((e) => [e.key, e.value]).toList());
    writer.writeList(obj.queryParams.map((e) => [e.key, e.value]).toList());
    writer.writeString(obj.bodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.executionTimePath);
    writer.writeString(obj.memoryPath);
  }
}
