import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String endpointUrl;

  @HiveField(3)
  String httpMethod;

  @HiveField(4)
  String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String requestBodyTemplate; // JSON with placeholders

  @HiveField(8)
  String responseStdoutPath;

  @HiveField(9)
  String responseStderrPath;

  @HiveField(10)
  String responseErrorPath;

  @HiveField(11)
  String responseExecutionTimePath;

  @HiveField(12)
  String responseMemoryPath;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.responseStdoutPath,
    required this.responseStderrPath,
    required this.responseErrorPath,
    required this.responseExecutionTimePath,
    required this.responseMemoryPath,
  });

  // Default Presets
  static List<CompilerPreset> get defaultPresets {
    return [
      CompilerPreset(
        id: 'onecompiler',
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        responseStdoutPath: 'stdout',
        responseStderrPath: 'stderr',
        responseErrorPath: 'exception',
        responseExecutionTimePath: 'executionTime',
        responseMemoryPath: 'limitReachMessage',
      ),
      CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle (Template)',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
        responseStdoutPath: 'output',
        responseStderrPath: '',
        responseErrorPath: 'error',
        responseExecutionTimePath: 'cpuTime',
        responseMemoryPath: 'memory',
      ),
      CompilerPreset(
        id: 'piston',
        name: 'Piston (Template)',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
        responseErrorPath: 'message',
        responseExecutionTimePath: 'run.time',
        responseMemoryPath: 'run.memory',
      ),
      CompilerPreset(
        id: 'replit',
        name: 'Replit (Template)',
        endpointUrl: 'https://api.replit.com/v1/execute',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "code": "{code}"}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: '',
        responseExecutionTimePath: 'time',
        responseMemoryPath: '',
      ),
      CompilerPreset(
        id: 'codex',
        name: 'CodeX (Template)',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: '',
        responseExecutionTimePath: 'timestamp',
        responseMemoryPath: '',
      ),
      CompilerPreset(
        id: 'hackerearth',
        name: 'HackerEarth (Template)',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'client-secret': 'YOUR_CLIENT_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{"lang": "DART", "source": "{code}", "input": "{stdin}"}',
        responseStdoutPath: 'result.run_status.output',
        responseStderrPath: 'result.run_status.stderr',
        responseErrorPath: 'message',
        responseExecutionTimePath: 'result.run_status.time_used',
        responseMemoryPath: 'result.run_status.memory_used',
      ),
    ];
  }
}
