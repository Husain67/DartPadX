import 'package:hive/hive.dart';
import 'dart:convert';

class CompilerPreset {
  final String id;
  String name;
  String endpointUrl;
  String httpMethod;
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  String authValue;
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate; // JSON template with {code}, {stdin}, {language}

  // Mapping paths (dot notation)
  String stdoutPath;
  String stderrPath;
  String errorPath;
  String timePath;
  String memoryPath;

  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.timePath,
    required this.memoryPath,
    this.isDefault = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'authValue': authValue,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'timePath': timePath,
      'memoryPath': memoryPath,
      'isDefault': isDefault,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'],
      name: json['name'],
      endpointUrl: json['endpointUrl'],
      httpMethod: json['httpMethod'],
      authType: json['authType'] ?? 'None',
      authValue: json['authValue'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] ?? '',
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      timePath: json['timePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

    static CompilerPreset get oneCompilerDefault {
    return CompilerPreset(
      id: 'default_onecompiler',
      name: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: const String.fromEnvironment('ONECOMPILER_KEY'),
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': '{auth}',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      queryParams: {},
      requestBodyTemplate: jsonEncode({
        "language": "dart",
        "stdin": "{stdin}",
        "files": [
          {
            "name": "main.dart",
            "content": "{code}"
          }
        ]
      }),
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      timePath: 'executionTime',
      memoryPath: 'memory',
      isDefault: true,
    );
  }

  static CompilerPreset get jdoodle {
    return CompilerPreset(
      id: 'default_jdoodle',
      name: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'content-type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: jsonEncode({
        "clientId": "your_client_id",
        "clientSecret": "your_client_secret",
        "script": "{code}",
        "language": "dart",
        "versionIndex": "0"
      }),
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      timePath: 'cpuTime',
      memoryPath: 'memory',
      isDefault: false,
    );
  }

  static CompilerPreset get piston {
    return CompilerPreset(
      id: 'default_piston',
      name: 'Piston',
      endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
      httpMethod: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'content-type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: jsonEncode({
        "language": "dart",
        "version": "*",
        "files": [{"content": "{code}"}]
      }),
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'message',
      timePath: '',
      memoryPath: '',
      isDefault: false,
    );
  }

  static CompilerPreset get replit {
    return CompilerPreset(
      id: 'default_replit',
      name: 'Replit',
      endpointUrl: 'https://replit.com/api/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: 'your_replit_key',
      headers: {'content-type': 'application/json', 'Authorization': 'Bearer {auth}'},
      queryParams: {},
      requestBodyTemplate: '{"code":"{code}"}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      timePath: '',
      memoryPath: '',
      isDefault: false,
    );
  }

  static CompilerPreset get codex {
    return CompilerPreset(
      id: 'default_codex',
      name: 'CodeX',
      endpointUrl: 'https://api.codex.jaagrav.in',
      httpMethod: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'content-type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{"code":"{code}","language":"dart"}',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      timePath: '',
      memoryPath: '',
      isDefault: false,
    );
  }

  static CompilerPreset get hackerEarth {
    return CompilerPreset(
      id: 'default_hackerearth',
      name: 'HackerEarth',
      endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: 'client_secret',
      headers: {'content-type': 'application/json', 'client-secret': '{auth}'},
      queryParams: {},
      requestBodyTemplate: '{"source":"{code}","lang":"DART"}',
      stdoutPath: 'result.run_status.output',
      stderrPath: 'result.run_status.stderr',
      errorPath: 'result.compile_status',
      timePath: 'result.run_status.time_used',
      memoryPath: 'result.run_status.memory_used',
      isDefault: false,
    );
  }

  static CompilerPreset get blankPreset {
    return CompilerPreset(
      id: 'default_blank',
      name: 'Blank',
      endpointUrl: '',
      httpMethod: 'POST',
      authType: 'None',
      authValue: '',
      headers: {},
      queryParams: {},
      requestBodyTemplate: '',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      timePath: '',
      memoryPath: '',
      isDefault: false,
    );
  }

  static List<CompilerPreset> get defaultPresets => [
    oneCompilerDefault, jdoodle, piston, replit, codex, hackerEarth, blankPreset
  ];
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
      authValue: fields[5] as String,
      headers: (fields[6] as Map).cast<String, String>(),
      queryParams: (fields[7] as Map).cast<String, String>(),
      requestBodyTemplate: fields[8] as String,
      stdoutPath: fields[9] as String,
      stderrPath: fields[10] as String,
      errorPath: fields[11] as String,
      timePath: fields[12] as String,
      memoryPath: fields[13] as String,
      isDefault: fields[14] as bool,
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
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.queryParams)
      ..writeByte(8)
      ..write(obj.requestBodyTemplate)
      ..writeByte(9)
      ..write(obj.stdoutPath)
      ..writeByte(10)
      ..write(obj.stderrPath)
      ..writeByte(11)
      ..write(obj.errorPath)
      ..writeByte(12)
      ..write(obj.timePath)
      ..writeByte(13)
      ..write(obj.memoryPath)
      ..writeByte(14)
      ..write(obj.isDefault);
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
