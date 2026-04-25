import 'package:hive/hive.dart';
import 'dart:convert';

class CompilerPreset {
  String id;
  String name;
  String url;
  String method;
  String authType;
  String authValue;
  List<MapEntry<String, String>> headers;
  List<MapEntry<String, String>> queryParams;
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
    this.headers = const [],
    this.queryParams = const [],
    this.bodyTemplate = '{}',
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
    'headers': headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
    'queryParams': queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
    'bodyTemplate': bodyTemplate,
    'stdoutPath': stdoutPath,
    'stderrPath': stderrPath,
    'errorPath': errorPath,
    'executionTimePath': executionTimePath,
    'memoryPath': memoryPath,
  };

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      authValue: json['authValue'] as String? ?? '',
      headers: (json['headers'] as List<dynamic>?)?.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String)).toList() ?? [],
      queryParams: (json['queryParams'] as List<dynamic>?)?.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String)).toList() ?? [],
      bodyTemplate: json['bodyTemplate'] as String? ?? '{}',
      stdoutPath: json['stdoutPath'] as String? ?? '',
      stderrPath: json['stderrPath'] as String? ?? '',
      errorPath: json['errorPath'] as String? ?? '',
      executionTimePath: json['executionTimePath'] as String? ?? '',
      memoryPath: json['memoryPath'] as String? ?? '',
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

    List<MapEntry<String, String>> parseEntries(String jsonStr) {
      if (jsonStr.isEmpty) return [];
      try {
        final list = jsonDecode(jsonStr) as List;
        return list.map((e) => MapEntry<String, String>(e['key'] as String, e['value'] as String)).toList();
      } catch (_) {
        return [];
      }
    }

    return CompilerPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      method: fields[3] as String? ?? 'POST',
      authType: fields[4] as String? ?? 'None',
      authValue: fields[5] as String? ?? '',
      headers: parseEntries(fields[6] as String? ?? '[]'),
      queryParams: parseEntries(fields[7] as String? ?? '[]'),
      bodyTemplate: fields[8] as String? ?? '{}',
      stdoutPath: fields[9] as String? ?? '',
      stderrPath: fields[10] as String? ?? '',
      errorPath: fields[11] as String? ?? '',
      executionTimePath: fields[12] as String? ?? '',
      memoryPath: fields[13] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    String encodeEntries(List<MapEntry<String, String>> entries) {
      return jsonEncode(entries.map((e) => {'key': e.key, 'value': e.value}).toList());
    }

    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authValue)
      ..writeByte(6)
      ..write(encodeEntries(obj.headers))
      ..writeByte(7)
      ..write(encodeEntries(obj.queryParams))
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
      ..write(obj.memoryPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompilerPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
