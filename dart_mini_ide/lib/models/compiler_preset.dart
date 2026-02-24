import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String method; // 'POST', 'GET', 'PUT'

  @HiveField(4)
  String authType; // 'None', 'Bearer Token', 'API Key Header'

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String bodyTemplate; // JSON with placeholders {code}, {stdin}, {language}

  @HiveField(8)
  Map<String, String> responseMapping; // 'stdout', 'stderr', 'executionTime', 'memory', 'error'

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate = '{"source_code": "{code}", "language_id": 71, "stdin": "{stdin}"}',
    this.responseMapping = const {
      'stdout': 'stdout',
      'stderr': 'stderr',
      'executionTime': 'time',
      'memory': 'memory',
    },
  });
}
