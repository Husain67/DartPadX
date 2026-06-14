import 'package:hive/hive.dart';

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
  String httpMethod;

  @HiveField(4)
  String authType;

  @HiveField(5)
  Map<String, String> headers;

  @HiveField(6)
  Map<String, String> queryParams;

  @HiveField(7)
  String requestBodyTemplate;

  @HiveField(8)
  Map<String, String> responseMapping;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.responseMapping,
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
    Map<String, String>? responseMapping,
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
      responseMapping: responseMapping ?? Map.from(this.responseMapping),
    );
  }
}
