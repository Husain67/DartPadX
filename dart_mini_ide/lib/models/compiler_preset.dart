import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpoint;

  @HiveField(3)
  String method; // GET, POST, PUT

  @HiveField(4)
  String authType; // None, Header, Bearer, Basic, Query

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String requestBodyTemplate; // JSON string

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

  @HiveField(13)
  bool isDefault;

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpoint,
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
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  CompilerPreset copyWith({
    String? name,
    String? endpoint,
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
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? Map.from(this.headers),
      queryParams: queryParams ?? Map.from(this.queryParams),
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
