import 'package:hive/hive.dart';

class HeaderModel {
  String key;
  String value;

  HeaderModel({required this.key, required this.value});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  factory HeaderModel.fromJson(Map<String, dynamic> json) => HeaderModel(
        key: json['key'] as String,
        value: json['value'] as String,
      );
}

class QueryParamModel {
  String key;
  String value;

  QueryParamModel({required this.key, required this.value});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  factory QueryParamModel.fromJson(Map<String, dynamic> json) =>
      QueryParamModel(
        key: json['key'] as String,
        value: json['value'] as String,
      );
}

class CompilerPreset extends HiveObject {
  String id;
  String name;
  String endpointUrl;
  String httpMethod; // POST, GET, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  String authValue; // Actual key/token
  List<HeaderModel> headers;
  List<QueryParamModel> queryParams;
  String requestBodyTemplate;
  String responseStdoutPath;
  String responseStderrPath;
  String responseErrorPath;
  String responseTimePath;
  String responseMemoryPath;
  bool isDefault;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.httpMethod,
    required this.authType,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.requestBodyTemplate,
    required this.responseStdoutPath,
    required this.responseStderrPath,
    required this.responseErrorPath,
    required this.responseTimePath,
    required this.responseMemoryPath,
    required this.isDefault,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? httpMethod,
    String? authType,
    String? authValue,
    List<HeaderModel>? headers,
    List<QueryParamModel>? queryParams,
    String? requestBodyTemplate,
    String? responseStdoutPath,
    String? responseStderrPath,
    String? responseErrorPath,
    String? responseTimePath,
    String? responseMemoryPath,
    bool? isDefault,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      httpMethod: httpMethod ?? this.httpMethod,
      authType: authType ?? this.authType,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      requestBodyTemplate: requestBodyTemplate ?? this.requestBodyTemplate,
      responseStdoutPath: responseStdoutPath ?? this.responseStdoutPath,
      responseStderrPath: responseStderrPath ?? this.responseStderrPath,
      responseErrorPath: responseErrorPath ?? this.responseErrorPath,
      responseTimePath: responseTimePath ?? this.responseTimePath,
      responseMemoryPath: responseMemoryPath ?? this.responseMemoryPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpointUrl': endpointUrl,
      'httpMethod': httpMethod,
      'authType': authType,
      'authValue': authValue,
      'headers': headers.map((e) => e.toJson()).toList(),
      'queryParams': queryParams.map((e) => e.toJson()).toList(),
      'requestBodyTemplate': requestBodyTemplate,
      'responseStdoutPath': responseStdoutPath,
      'responseStderrPath': responseStderrPath,
      'responseErrorPath': responseErrorPath,
      'responseTimePath': responseTimePath,
      'responseMemoryPath': responseMemoryPath,
      'isDefault': isDefault,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      endpointUrl: json['endpointUrl'] as String,
      httpMethod: json['httpMethod'] as String,
      authType: json['authType'] as String,
      authValue: json['authValue'] as String,
      headers: (json['headers'] as List<dynamic>?)
              ?.map((e) => HeaderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      queryParams: (json['queryParams'] as List<dynamic>?)
              ?.map((e) => QueryParamModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requestBodyTemplate: json['requestBodyTemplate'] as String,
      responseStdoutPath: json['responseStdoutPath'] as String,
      responseStderrPath: json['responseStderrPath'] as String,
      responseErrorPath: json['responseErrorPath'] as String,
      responseTimePath: json['responseTimePath'] as String,
      responseMemoryPath: json['responseMemoryPath'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
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

    // Parse headers manually as List<Map> is saved dynamically
    List<HeaderModel> parsedHeaders = [];
    if (fields[6] != null) {
      final rawList = fields[6] as List;
      for (var item in rawList) {
        if (item is Map) {
          parsedHeaders.add(HeaderModel(
            key: item['key'].toString(),
            value: item['value'].toString(),
          ));
        }
      }
    }

    // Parse query params manually
    List<QueryParamModel> parsedQueryParams = [];
    if (fields[7] != null) {
      final rawList = fields[7] as List;
      for (var item in rawList) {
        if (item is Map) {
          parsedQueryParams.add(QueryParamModel(
            key: item['key'].toString(),
            value: item['value'].toString(),
          ));
        }
      }
    }

    return CompilerPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      endpointUrl: fields[2] as String,
      httpMethod: fields[3] as String,
      authType: fields[4] as String,
      authValue: fields[5] as String,
      headers: parsedHeaders,
      queryParams: parsedQueryParams,
      requestBodyTemplate: fields[8] as String,
      responseStdoutPath: fields[9] as String,
      responseStderrPath: fields[10] as String,
      responseErrorPath: fields[11] as String,
      responseTimePath: fields[12] as String,
      responseMemoryPath: fields[13] as String,
      isDefault: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.authValue)
      ..writeByte(6)
      ..write(obj.headers.map((e) => e.toJson()).toList())
      ..writeByte(7)
      ..write(obj.queryParams.map((e) => e.toJson()).toList())
      ..writeByte(8)
      ..write(obj.requestBodyTemplate)
      ..writeByte(9)
      ..write(obj.responseStdoutPath)
      ..writeByte(10)
      ..write(obj.responseStderrPath)
      ..writeByte(11)
      ..write(obj.responseErrorPath)
      ..writeByte(12)
      ..write(obj.responseTimePath)
      ..writeByte(13)
      ..write(obj.responseMemoryPath)
      ..writeByte(14)
      ..write(obj.isDefault);
  }
}
