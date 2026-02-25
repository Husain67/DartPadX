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
  String method;

  @HiveField(4)
  Map<String, String> headers;

  @HiveField(5)
  String bodyTemplate;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  Map<String, String> responseMapping;

  @HiveField(8)
  bool isDefault;

  @HiveField(9)
  String authType; // 'none', 'header', 'bearer', 'basic', 'query'

  @HiveField(10)
  String authKey;

  @HiveField(11)
  String authValue;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.headers,
    required this.bodyTemplate,
    required this.queryParams,
    required this.responseMapping,
    this.isDefault = false,
    this.authType = 'none',
    this.authKey = '',
    this.authValue = '',
  });

  // Helper factory for default OneCompiler
  factory CompilerPreset.oneCompiler() {
    return CompilerPreset(
      id: 'default_onecompiler',
      name: 'OneCompiler (Default)',
      url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      queryParams: {},
      responseMapping: {
        'stdout': 'stdout',
        'stderr': 'stderr',
        'executionTime': 'executionTime',
        'memory': 'memory',
        'error': 'exception'
      },
      isDefault: true,
      authType: 'header',
      authKey: 'X-RapidAPI-Key',
      authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
    );
  }
}
