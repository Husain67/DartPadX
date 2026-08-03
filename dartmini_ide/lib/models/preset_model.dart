

class PresetModel {
  final String id;
  final String name;
  final String endpoint;
  final String method;
  final String authType; // 'None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'
  final String authValue;
  final String authKey; // used if header/query param
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate;
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;

  PresetModel({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.method,
    required this.authType,
    this.authValue = '',
    this.authKey = '',
    this.headers = const {},
    this.queryParams = const {},
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
  });
}
