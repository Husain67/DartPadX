import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  String platformName;
  String endpointUrl;
  String httpMethod;
  String authType;
  String authValue;
  List<MapEntry<String, String>> headers;
  List<MapEntry<String, String>> queryParams;
  String requestBodyTemplate;
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;
  bool isReadOnly; // For pre-loaded presets

  CompilerPreset({
    required this.id,
    required this.platformName,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    this.authValue = '',
    this.headers = const [],
    this.queryParams = const [],
    this.requestBodyTemplate = '{}',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isReadOnly = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? platformName,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authValue,
    List<MapEntry<String, String>>? headers,
    List<MapEntry<String, String>>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isReadOnly,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? List.from(this.headers),
      queryParams: queryParams ?? List.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platformName': platformName,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'authValue': authValue,
      'headers': headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'queryParams': queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'requestBodyTemplate': requestBodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isReadOnly': isReadOnly,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      platformName: json['platformName'] as String,
      endpointUrl: json['endpointUrl'] as String,
      httpMethod: json['httpMethod'] as String,
      authType: json['authType'] as String,
      authValue: json['authValue'] as String? ?? '',
      headers: (json['headers'] as List?)
              ?.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String))
              .toList() ??
          [],
      queryParams: (json['queryParams'] as List?)
              ?.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String))
              .toList() ??
          [],
      requestBodyTemplate: json['requestBodyTemplate'] as String,
      stdoutPath: json['stdoutPath'] as String,
      stderrPath: json['stderrPath'] as String,
      errorPath: json['errorPath'] as String,
      executionTimePath: json['executionTimePath'] as String,
      memoryPath: json['memoryPath'] as String,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
    );
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final Map<int, dynamic> fields = {};
    for (int i = 0; i < fieldsCount; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    final headerList = (fields[6] as List?)?.cast<String>() ?? [];
    final headers = <MapEntry<String, String>>[];
    for (int i = 0; i < headerList.length; i += 2) {
      if (i + 1 < headerList.length) {
        headers.add(MapEntry(headerList[i], headerList[i + 1]));
      }
    }

    final queryList = (fields[7] as List?)?.cast<String>() ?? [];
    final queryParams = <MapEntry<String, String>>[];
    for (int i = 0; i < queryList.length; i += 2) {
      if (i + 1 < queryList.length) {
        queryParams.add(MapEntry(queryList[i], queryList[i + 1]));
      }
    }

    return CompilerPreset(
      id: fields[0] as String,
      platformName: fields[1] as String,
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      authValue: fields[5] as String? ?? '',
      headers: headers,
      queryParams: queryParams,
      requestBodyTemplate: fields[8] as String,
      stdoutPath: fields[9] as String,
      stderrPath: fields[10] as String,
      errorPath: fields[11] as String,
      executionTimePath: fields[12] as String,
      memoryPath: fields[13] as String,
      isReadOnly: fields[14] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeByte(15);

    writer.writeByte(0);
    writer.write(obj.id);

    writer.writeByte(1);
    writer.write(obj.platformName);

    writer.writeByte(2);
    writer.write(obj.endpointUrl);

    writer.writeByte(3);
    writer.write(obj.httpMethod);

    writer.writeByte(4);
    writer.write(obj.authType);

    writer.writeByte(5);
    writer.write(obj.authValue);

    writer.writeByte(6);
    final headerList = <String>[];
    for (var e in obj.headers) {
      headerList.add(e.key);
      headerList.add(e.value);
    }
    writer.write(headerList);

    writer.writeByte(7);
    final queryList = <String>[];
    for (var e in obj.queryParams) {
      queryList.add(e.key);
      queryList.add(e.value);
    }
    writer.write(queryList);

    writer.writeByte(8);
    writer.write(obj.requestBodyTemplate);

    writer.writeByte(9);
    writer.write(obj.stdoutPath);

    writer.writeByte(10);
    writer.write(obj.stderrPath);

    writer.writeByte(11);
    writer.write(obj.errorPath);

    writer.writeByte(12);
    writer.write(obj.executionTimePath);

    writer.writeByte(13);
    writer.write(obj.memoryPath);

    writer.writeByte(14);
    writer.write(obj.isReadOnly);
  }
}
