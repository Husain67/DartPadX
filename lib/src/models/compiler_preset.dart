import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';


class CompilerPreset {
  final String id;
  final String name;
  final String url;
  final String method;
  final String authType;
  final String authValue;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate;
  final Map<String, String> mappings;

  CompilerPreset({
    String? id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.authValue = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '{"content": "{code}"}',
    this.mappings = const {
      'stdout': '',
      'stderr': '',
      'error': '',
      'executionTime': '',
      'memory': ''
    },
  }) : id = id ?? const Uuid().v4();

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    Map<String, String>? mappings,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      mappings: mappings ?? this.mappings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'method': method,
      'authType': authType,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'mappings': mappings,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String?,
      name: json['name'] as String,
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      authValue: json['authValue'] as String? ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      bodyTemplate: json['bodyTemplate'] as String? ?? '{"content": "{code}"}',
      mappings: Map<String, String>.from(json['mappings'] ?? {
        'stdout': '',
        'stderr': '',
        'error': '',
        'executionTime': '',
        'memory': ''
      }),
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
      url: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      authValue: fields[5] as String,
      headers: (fields[6] as Map).cast<String, String>(),
      queryParams: (fields[7] as Map).cast<String, String>(),
      bodyTemplate: fields[8] as String,
      mappings: (fields[9] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.queryParams)
      ..writeByte(8)
      ..write(obj.bodyTemplate)
      ..writeByte(9)
      ..write(obj.mappings);
  }
}
