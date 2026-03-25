import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  String name;
  String url;
  String method;
  String authType;
  String authValue;
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
    this.method = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'method': method,
        'authType': authType,
        'authValue': authValue,
        'headers': headers,
        'queryParams': queryParams,
        'bodyTemplate': bodyTemplate,
        'stdoutPath': stdoutPath,
        'stderrPath': stderrPath,
        'errorPath': errorPath,
        'executionTimePath': executionTimePath,
        'memoryPath': memoryPath,
      };

  factory CompilerPreset.fromJson(Map<String, dynamic> json) => CompilerPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        method: json['method'] as String? ?? 'POST',
        authType: json['authType'] as String? ?? 'None',
        authValue: json['authValue'] as String? ?? '',
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
      headers: Map<String, String>.from(reader.readMap()),
      queryParams: Map<String, String>.from(reader.readMap()),
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
    writer.writeString(obj.authValue);
    writer.writeMap(obj.headers);
    writer.writeMap(obj.queryParams);
    writer.writeString(obj.bodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.executionTimePath);
    writer.writeString(obj.memoryPath);
  }
}
