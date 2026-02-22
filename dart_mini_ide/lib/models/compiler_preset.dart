import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpointUrl;

  @HiveField(3)
  String method; // 'POST', 'GET', 'PUT'

  @HiveField(4)
  String authType; // 'None', 'API-Key', 'Bearer', 'Basic'

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String requestBodyTemplate; // JSON with {code}, {language}

  @HiveField(8)
  String stdoutPath;

  @HiveField(9)
  String stderrPath;

  @HiveField(10)
  String errorPath;

  @HiveField(11)
  String executionTimePath;

  @HiveField(12)
  String memoryPath;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpointUrl,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '{}',
    this.stdoutPath = 'stdout',
    this.stderrPath = 'stderr',
    this.errorPath = 'error',
    this.executionTimePath = 'executionTime',
    this.memoryPath = 'memory',
  }) : id = id ?? const Uuid().v4();

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? method,
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
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }
}
