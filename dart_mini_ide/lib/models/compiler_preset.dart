
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CompilerPreset extends HiveObject {
  String id;
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

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });

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
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Imported Preset',
      endpointUrl: json['endpointUrl'] as String? ?? '',
      httpMethod: json['httpMethod'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] as String? ?? '',
      stdoutPath: json['stdoutPath'] as String? ?? '',
      stderrPath: json['stderrPath'] as String? ?? '',
      errorPath: json['errorPath'] as String? ?? '',
      executionTimePath: json['executionTimePath'] as String? ?? '',
      memoryPath: json['memoryPath'] as String? ?? '',
    );
  }

  static List<CompilerPreset> getDefaultPresets() {
    return [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'x-rapidapi-key': const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          'Content-Type': 'application/json'
        },
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": {code}, "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "*", "files": [{"name": "main.dart", "content": {code}}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/run', // Example
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": {code}}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'client-secret': 'YOUR_CLIENT_SECRET', 'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"source": {code}, "lang": "DART", "input": "{stdin}", "memory_limit": 262144, "time_limit": 5}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'errors',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];
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
      stdoutPath: fields[8] as String,
      stderrPath: fields[9] as String,
      errorPath: fields[10] as String,
      executionTimePath: fields[11] as String,
      memoryPath: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.stdoutPath)
      ..writeByte(9)
      ..write(obj.stderrPath)
      ..writeByte(10)
      ..write(obj.errorPath)
      ..writeByte(11)
      ..write(obj.executionTimePath)
      ..writeByte(12)
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
