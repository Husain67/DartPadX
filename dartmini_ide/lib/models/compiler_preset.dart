import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CompilerPreset extends HiveObject {
  final String id;
  String name;
  String endpointUrl;
  String httpMethod;
  String authType;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;
  bool isDefault;

  CompilerPreset({
    String? id,
    required this.name,
    this.endpointUrl = '',
    this.httpMethod = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

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
    bool? isDefault,
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
      isDefault: isDefault ?? this.isDefault,
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
      endpointUrl: reader.readString(),
      httpMethod: reader.readString(),
      authType: reader.readString(),
      headers: Map<String, String>.from(reader.readMap()),
      queryParams: Map<String, String>.from(reader.readMap()),
      requestBodyTemplate: reader.readString(),
      stdoutPath: reader.readString(),
      stderrPath: reader.readString(),
      errorPath: reader.readString(),
      executionTimePath: reader.readString(),
      memoryPath: reader.readString(),
      isDefault: reader.readBool(),
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
    writer.writeBool(obj.isDefault);
  }
}
