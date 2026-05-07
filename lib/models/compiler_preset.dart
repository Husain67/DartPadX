import 'package:uuid/uuid.dart';

class CompilerPreset {
  final String id;
  final String name;
  final String endpointUrl;
  final String httpMethod; // POST, GET, PUT
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  final String authKey; // Key name for Header/Query
  final String authValue;
  final List<MapEntry<String, String>> headers;
  final List<MapEntry<String, String>> queryParams;
  final String requestBodyTemplate; // JSON with {code}, {language}, {stdin}
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;
  final bool isDefault; // Whether this is the built-in onecompiler preset

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.authKey,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authKey,
    String? authValue,
    List<MapEntry<String, String>>? headers,
    List<MapEntry<String, String>>? queryParams,
    String? requestBodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'authKey': authKey,
      'authValue': authValue,
      'headers': headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'queryParams': queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'requestBodyTemplate': requestBodyTemplate,
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'executionTimePath': executionTimePath,
      'memoryPath': memoryPath,
      'isDefault': isDefault,
    };
  }

  factory CompilerPreset.fromMap(Map<dynamic, dynamic> map) {
    List<MapEntry<String, String>> parseList(dynamic list) {
      if (list == null) return [];
      if (list is List) {
        return list.map<MapEntry<String, String>>((e) {
          if (e is Map) {
             return MapEntry(e['key']?.toString() ?? '', e['value']?.toString() ?? '');
          }
          return const MapEntry('', '');
        }).toList();
      }
      return [];
    }

    return CompilerPreset(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      endpointUrl: map['endpointUrl']?.toString() ?? '',
      httpMethod: map['httpMethod']?.toString() ?? 'POST',
      authType: map['authType']?.toString() ?? 'None',
      authKey: map['authKey']?.toString() ?? '',
      authValue: map['authValue']?.toString() ?? '',
      headers: parseList(map['headers']),
      queryParams: parseList(map['queryParams']),
      requestBodyTemplate: map['requestBodyTemplate']?.toString() ?? '',
      stdoutPath: map['stdoutPath']?.toString() ?? '',
      stderrPath: map['stderrPath']?.toString() ?? '',
      errorPath: map['errorPath']?.toString() ?? '',
      executionTimePath: map['executionTimePath']?.toString() ?? '',
      memoryPath: map['memoryPath']?.toString() ?? '',
      isDefault: map['isDefault'] == true,
    );
  }
}
