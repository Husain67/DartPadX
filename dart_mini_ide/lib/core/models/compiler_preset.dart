import 'package:hive/hive.dart';

part 'compiler_preset.g.dart';

@HiveType(typeId: 1)
class CompilerPreset {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String method; // 'POST', 'GET', etc.

  @HiveField(4)
  final String authType; // 'None', 'API-Key', 'Bearer', 'Basic'

  @HiveField(5)
  final Map<String, String> headers;

  @HiveField(6)
  final Map<String, String> queryParams;

  @HiveField(7)
  final String requestBodyTemplate; // JSON string with placeholders {code}, {stdin}, etc.

  @HiveField(8)
  final Map<String, String> responseMapping; // Map keys to JSON paths (e.g. 'stdout' -> 'output.stdout')

  CompilerPreset({
    required this.id,
    required this.name,
    required this.url,
    required this.method,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.responseMapping,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? requestBodyTemplate,
    Map<String, String>? responseMapping,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseMapping: responseMapping ?? this.responseMapping,
    );
  }
}
