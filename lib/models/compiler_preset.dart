import 'package:hive/hive.dart';

class CompilerPreset {
  String id;
  String name;
  String endpoint;
  String method; // 'POST', 'GET', 'PUT'
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'
  String authKey;
  String authValue;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;

  // Response Mappings
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.authKey = '',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '{}',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'method': method,
      'authType': authType,
      'authKey': authKey,
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
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      endpoint: json['endpoint'] ?? '',
      method: json['method'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      authKey: json['authKey'] ?? '',
      authValue: json['authValue'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] ?? '{}',
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
      endpoint: reader.readString(),
      method: reader.readString(),
      authType: reader.readString(),
      authKey: reader.readString(),
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
    writer.writeString(obj.endpoint);
    writer.writeString(obj.method);
    writer.writeString(obj.authType);
    writer.writeString(obj.authKey);
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
