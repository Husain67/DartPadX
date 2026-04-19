import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  String name;
  String endpointUrl;
  String httpMethod;
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  String authValue;
  List<MapEntry<String, String>> headers;
  List<MapEntry<String, String>> queryParams;
  String bodyTemplate; // {code}, {stdin}, {language}
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String executionTimePath;
  String memoryPath;
  bool isBuiltIn;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
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
      'isBuiltIn': isBuiltIn,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'],
      endpointUrl: json['endpointUrl'],
      httpMethod: json['httpMethod'],
      authType: json['authType'],
      authValue: json['authValue'],
      headers: (json['headers'] as List?)?.map((e) => MapEntry<String, String>(e['key'], e['value'])).toList() ?? [],
      queryParams: (json['queryParams'] as List?)?.map((e) => MapEntry<String, String>(e['key'], e['value'])).toList() ?? [],
      bodyTemplate: json['bodyTemplate'],
      stdoutPath: json['stdoutPath'],
      stderrPath: json['stderrPath'],
      errorPath: json['errorPath'],
      executionTimePath: json['executionTimePath'],
      memoryPath: json['memoryPath'],
      isBuiltIn: json['isBuiltIn'] ?? false,
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

    List<MapEntry<String, String>> parseList(dynamic list) {
        if (list == null) return [];
        return (list as List).map((e) {
          final m = e as Map;
          return MapEntry<String, String>(m['key'] as String, m['value'] as String);
        }).toList();
    }

    return CompilerPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      authValue: fields[5] as String,
      headers: parseList(fields[6]),
      queryParams: parseList(fields[7]),
      bodyTemplate: fields[8] as String,
      stdoutPath: fields[9] as String,
      stderrPath: fields[10] as String,
      errorPath: fields[11] as String,
      executionTimePath: fields[12] as String,
      memoryPath: fields[13] as String,
      isBuiltIn: fields[14] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.endpointUrl)
      ..writeByte(3)
      ..write(obj.httpMethod)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authValue)
      ..writeByte(6)
      ..write(obj.headers.map((e) => {'key': e.key, 'value': e.value}).toList())
      ..writeByte(7)
      ..write(obj.queryParams.map((e) => {'key': e.key, 'value': e.value}).toList())
      ..writeByte(8)
      ..write(obj.bodyTemplate)
      ..writeByte(9)
      ..write(obj.stdoutPath)
      ..writeByte(10)
      ..write(obj.stderrPath)
      ..writeByte(11)
      ..write(obj.errorPath)
      ..writeByte(12)
      ..write(obj.executionTimePath)
      ..writeByte(13)
      ..write(obj.memoryPath)
      ..writeByte(14)
      ..write(obj.isBuiltIn);
  }
}
