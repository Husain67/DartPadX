import 'package:hive/hive.dart';

class PresetModel extends HiveObject {
  String id;
  String name;
  String endpoint;
  String httpMethod;
  String authType;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String timePath;
  String memoryPath;

  PresetModel({
    required this.id,
    required this.name,
    required this.endpoint,
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.timePath = '',
    this.memoryPath = '',
  });

  PresetModel copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
  }) {
    return PresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
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

  factory PresetModel.fromJson(Map<String, dynamic> json) {
    return PresetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      endpoint: json['endpoint'] ?? '',
      httpMethod: json['httpMethod'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] ?? '',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      timePath: json['timePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'httpMethod': httpMethod,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'timePath': timePath,
      'memoryPath': memoryPath,
    };
  }
}

class PresetModelAdapter extends TypeAdapter<PresetModel> {
  @override
  final int typeId = 1;

  @override
  PresetModel read(BinaryReader reader) {
    return PresetModel(
      id: reader.readString(),
      name: reader.readString(),
      endpoint: reader.readString(),
      httpMethod: reader.readString(),
      authType: reader.readString(),
      headers: reader.readMap().cast<String, String>(),
      queryParams: reader.readMap().cast<String, String>(),
      bodyTemplate: reader.readString(),
      stdoutPath: reader.readString(),
      stderrPath: reader.readString(),
      errorPath: reader.readString(),
      timePath: reader.readString(),
      memoryPath: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, PresetModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.endpoint);
    writer.writeString(obj.httpMethod);
    writer.writeString(obj.authType);
    writer.writeMap(obj.headers);
    writer.writeMap(obj.queryParams);
    writer.writeString(obj.bodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.timePath);
    writer.writeString(obj.memoryPath);
  }
}
