import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String platform;

  @HiveField(2)
  String endpointUrl;

  @HiveField(3)
  String method;

  @HiveField(4)
  String authType;

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String bodyTemplate;

  @HiveField(8)
  Map<String, String> responseMapping;

  CompilerPreset({
    required this.name,
    required this.platform,
    required this.endpointUrl,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '',
    this.responseMapping = const {
      'stdout': 'stdout',
      'stderr': 'stderr',
      'error': 'error',
      'executionTime': 'executionTime',
      'memory': 'memory',
    },
  });

  CompilerPreset copyWith({
    String? name,
    String? platform,
    String? endpointUrl,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    Map<String, String>? responseMapping,
  }) {
    return CompilerPreset(
      name: name ?? this.name,
      platform: platform ?? this.platform,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseMapping: responseMapping ?? this.responseMapping,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'platform': platform,
    'endpointUrl': endpointUrl,
    'method': method,
    'authType': authType,
    'headers': headers,
    'queryParams': queryParams,
    'bodyTemplate': bodyTemplate,
    'responseMapping': responseMapping,
  };

  factory CompilerPreset.fromJson(Map<String, dynamic> json) => CompilerPreset(
    name: json['name'],
    platform: json['platform'],
    endpointUrl: json['endpointUrl'],
    method: json['method'],
    authType: json['authType'],
    headers: Map<String, String>.from(json['headers'] ?? {}),
    queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
    bodyTemplate: json['bodyTemplate'],
    responseMapping: Map<String, String>.from(json['responseMapping'] ?? {}),
  );
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
      name: fields[0] as String,
      platform: fields[1] as String,
      endpointUrl: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      headers: (fields[5] as Map).cast<String, String>(),
      queryParams: (fields[6] as Map).cast<String, String>(),
      bodyTemplate: fields[7] as String,
      responseMapping: (fields[8] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.platform)
      ..writeByte(2)
      ..write(obj.endpointUrl)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.queryParams)
      ..writeByte(7)
      ..write(obj.bodyTemplate)
      ..writeByte(8)
      ..write(obj.responseMapping);
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
