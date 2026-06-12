import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'response_mapping.dart';

class CompilerPreset extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String endpointUrl;

  @HiveField(3)
  final String httpMethod; // GET, POST, PUT

  @HiveField(4)
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param

  @HiveField(5)
  final Map<String, String> headers;

  @HiveField(6)
  final Map<String, String> queryParams;

  @HiveField(7)
  final String requestBodyTemplate; // JSON template with {code}, {stdin}, {language}

  @HiveField(8)
  final ResponseMapping responseMapping;

  @HiveField(9)
  final bool isDefault;

  @HiveField(10)
  final bool isReadOnly;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpointUrl,
    this.httpMethod = 'POST',
    this.authType = 'None',
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.requestBodyTemplate = '',
    required this.responseMapping,
    this.isDefault = false,
    this.isReadOnly = false,
  })  : id = id ?? const Uuid().v4(),
        headers = headers ?? {},
        queryParams = queryParams ?? {};

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    ResponseMapping? responseMapping,
    bool? isDefault,
    bool? isReadOnly,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseMapping: responseMapping ?? this.responseMapping,
      isDefault: isDefault ?? this.isDefault,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'responseMapping': responseMapping.toJson(),
      'isDefault': isDefault,
      'isReadOnly': isReadOnly,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'] ?? '',
      endpointUrl: json['endpointUrl'] ?? '',
      httpMethod: json['httpMethod'] ?? 'POST',
      authType: json['authType'] ?? 'None',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] ?? '',
      responseMapping: ResponseMapping.fromJson(json['responseMapping'] ?? {}),
      isDefault: json['isDefault'] ?? false,
      isReadOnly: json['isReadOnly'] ?? false,
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
    return CompilerPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      requestBodyTemplate: fields[7] as String,
      responseMapping: fields[8] as ResponseMapping,
      isDefault: fields[9] as bool,
      isReadOnly: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.requestBodyTemplate)
      ..writeByte(8)
      ..write(obj.responseMapping)
      ..writeByte(9)
      ..write(obj.isDefault)
      ..writeByte(10)
      ..write(obj.isReadOnly);
  }
}
