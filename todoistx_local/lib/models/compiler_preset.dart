import 'package:hive/hive.dart';

class CompilerPreset {
  final String id;
  String name;
  String url;
  String method;
  String authType;
  String authCredentials;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String bodyTemplate;
  Map<String, String> responseMappings;
  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.authCredentials = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate =
        '{"code": "{code}", "language": "dart", "stdin": "{stdin}"}',
    this.responseMappings = const {
      'stdout': 'stdout',
      'stderr': 'stderr',
      'error': 'error',
      'executionTime': 'time',
      'memory': 'memory',
    },
    this.isDefault = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    String? authCredentials,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    Map<String, String>? responseMappings,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authCredentials: authCredentials ?? this.authCredentials,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      responseMappings: responseMappings ?? Map.from(this.responseMappings),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'method': method,
      'authType': authType,
      'authCredentials': authCredentials,
      'headers': headers,
      'queryParams': queryParams,
      'bodyTemplate': bodyTemplate,
      'responseMappings': responseMappings,
      'isDefault': isDefault,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      authCredentials: json['authCredentials'] as String? ?? '',
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      bodyTemplate: json['bodyTemplate'] as String? ??
          '{"code": "{code}", "language": "dart", "stdin": "{stdin}"}',
      responseMappings:
          Map<String, String>.from(json['responseMappings'] as Map? ?? {}),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = {
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompilerPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      method: fields[3] as String,
      authType: fields[4] as String,
      authCredentials: fields[5] as String,
      headers: (fields[6] as Map).cast<String, String>(),
      queryParams: (fields[7] as Map).cast<String, String>(),
      bodyTemplate: fields[8] as String,
      responseMappings: (fields[9] as Map).cast<String, String>(),
      isDefault: fields[10] as bool,
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
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.authType)
      ..writeByte(5)
      ..write(obj.authCredentials)
      ..writeByte(6)
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.queryParams)
      ..writeByte(8)
      ..write(obj.bodyTemplate)
      ..writeByte(9)
      ..write(obj.responseMappings)
      ..writeByte(10)
      ..write(obj.isDefault);
  }
}
