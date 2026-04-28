import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String endpoint;
  final String method; // POST, GET, PUT
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  final String authKey; // Header/Query key or username for Basic
  final String authValue; // Actual key/token or password for Basic
  final List<MapEntry<String, String>> headers;
  final List<MapEntry<String, String>> queryParams;
  final String bodyTemplate; // JSON template with {code}, {stdin}, {language}
  final String stdoutPath; // dot.notation.path
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;
  final bool isDefaultSystem;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.authKey = '',
    this.authValue = '',
    this.headers = const [],
    this.queryParams = const [],
    this.bodyTemplate = '',
    this.stdoutPath = '',
    this.stderrPath = '',
    this.errorPath = '',
    this.executionTimePath = '',
    this.memoryPath = '',
    this.isDefaultSystem = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? method,
    String? authType,
    String? authKey,
    String? authValue,
    List<MapEntry<String, String>>? headers,
    List<MapEntry<String, String>>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefaultSystem,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefaultSystem: isDefaultSystem ?? this.isDefaultSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'method': method,
      'authType': authType,
      'authKey': authKey,
      'authValue': authValue,
      'headers': headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'queryParams': queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'bodyTemplate': bodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isDefaultSystem': isDefaultSystem,
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
      headers: (json['headers'] as List?)?.map((e) => MapEntry<String, String>(e['key'] ?? '', e['value'] ?? '')).toList() ?? [],
      queryParams: (json['queryParams'] as List?)?.map((e) => MapEntry<String, String>(e['key'] ?? '', e['value'] ?? '')).toList() ?? [],
      bodyTemplate: json['bodyTemplate'] ?? '',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      executionTimePath: json['executionTimePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
      isDefaultSystem: json['isDefaultSystem'] ?? false,
    );
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    List<MapEntry<String, String>> parseList(dynamic data) {
      if (data == null) return [];
      final list = (data as List).cast<Map>();
      return list.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String)).toList();
    }

    return CompilerPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      endpoint: fields[2] as String,
      method: fields[3] as String? ?? 'POST',
      authType: fields[4] as String? ?? 'None',
      authKey: fields[5] as String? ?? '',
      authValue: fields[6] as String? ?? '',
      headers: parseList(fields[7]),
      queryParams: parseList(fields[8]),
      bodyTemplate: fields[9] as String? ?? '',
      stdoutPath: fields[10] as String? ?? '',
      stderrPath: fields[11] as String? ?? '',
      errorPath: fields[12] as String? ?? '',
      executionTimePath: fields[13] as String? ?? '',
      memoryPath: fields[14] as String? ?? '',
      isDefaultSystem: fields[15] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.endpoint)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authKey)
      ..writeByte(6)
      ..write(obj.authValue)
      ..writeByte(7)
      ..write(obj.headers.map((e) => {'key': e.key, 'value': e.value}).toList())
      ..writeByte(8)
      ..write(obj.queryParams.map((e) => {'key': e.key, 'value': e.value}).toList())
      ..writeByte(9)
      ..write(obj.bodyTemplate)
      ..writeByte(10)
      ..write(obj.stdoutPath)
      ..writeByte(11)
      ..write(obj.stderrPath)
      ..writeByte(12)
      ..write(obj.errorPath)
      ..writeByte(13)
      ..write(obj.executionTimePath)
      ..writeByte(14)
      ..write(obj.memoryPath)
      ..writeByte(15)
      ..write(obj.isDefaultSystem);
  }
}
