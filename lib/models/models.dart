import 'package:hive/hive.dart';

class CodeFile {
  final String id;
  String name;
  String content;
  String language;

  CodeFile({
    required this.id,
    required this.name,
    required this.content,
    this.language = 'dart',
  });

  CodeFile copyWith({
    String? id,
    String? name,
    String? content,
    String? language,
  }) {
    return CodeFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      language: language ?? this.language,
    );
  }
}

class CompilerPreset {
  final String id;
  final String name;
  final String endpointUrl;
  final String method; // POST, GET, PUT
  final String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  final String authKey;
  final String authValue;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String bodyTemplate;
  final String stdoutPath;
  final String stderrPath;
  final String errorPath;
  final String executionTimePath;
  final String memoryPath;
  final bool isReadOnly;

  CompilerPreset({
    required this.id,
    required this.name,
    required this.endpointUrl,
    required this.method,
    required this.authType,
    required this.authKey,
    required this.authValue,
    required this.headers,
    required this.queryParams,
    required this.bodyTemplate,
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.executionTimePath,
    required this.memoryPath,
    this.isReadOnly = false,
  });

  CompilerPreset copyWith({
    String? id,
    String? name,
    String? endpointUrl,
    String? method,
    String? authType,
    String? authKey,
    String? authValue,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? bodyTemplate,
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
    bool? isReadOnly,
  }) {
    return CompilerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      authKey: authKey ?? this.authKey,
      authValue: authValue ?? this.authValue,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      executionTimePath: executionTimePath ?? this.executionTimePath,
      memoryPath: memoryPath ?? this.memoryPath,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

class CodeFileAdapter extends TypeAdapter<CodeFile> {
  @override
  final int typeId = 0;

  @override
  CodeFile read(BinaryReader reader) {
    return CodeFile(
      id: reader.readString(),
      name: reader.readString(),
      content: reader.readString(),
      language: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, CodeFile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.content);
    writer.writeString(obj.language);
  }
}

class CompilerPresetAdapter extends TypeAdapter<CompilerPreset> {
  @override
  final int typeId = 1;

  @override
  CompilerPreset read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final endpointUrl = reader.readString();
    final method = reader.readString();
    final authType = reader.readString();
    final authKey = reader.readString();
    final authValue = reader.readString();

    final headersCount = reader.readInt();
    final headers = <String, String>{};
    for (var i = 0; i < headersCount; i++) {
      headers[reader.readString()] = reader.readString();
    }

    final queryParamsCount = reader.readInt();
    final queryParams = <String, String>{};
    for (var i = 0; i < queryParamsCount; i++) {
      queryParams[reader.readString()] = reader.readString();
    }

    final bodyTemplate = reader.readString();
    final stdoutPath = reader.readString();
    final stderrPath = reader.readString();
    final errorPath = reader.readString();
    final executionTimePath = reader.readString();
    final memoryPath = reader.readString();
    final isReadOnly = reader.readBool();

    return CompilerPreset(
      id: id,
      name: name,
      endpointUrl: endpointUrl,
      method: method,
      authType: authType,
      authKey: authKey,
      authValue: authValue,
      headers: headers,
      queryParams: queryParams,
      bodyTemplate: bodyTemplate,
      stdoutPath: stdoutPath,
      stderrPath: stderrPath,
      errorPath: errorPath,
      executionTimePath: executionTimePath,
      memoryPath: memoryPath,
      isReadOnly: isReadOnly,
    );
  }

  @override
  void write(BinaryWriter writer, CompilerPreset obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.endpointUrl);
    writer.writeString(obj.method);
    writer.writeString(obj.authType);
    writer.writeString(obj.authKey);
    writer.writeString(obj.authValue);

    writer.writeInt(obj.headers.length);
    obj.headers.forEach((key, value) {
      writer.writeString(key);
      writer.writeString(value);
    });

    writer.writeInt(obj.queryParams.length);
    obj.queryParams.forEach((key, value) {
      writer.writeString(key);
      writer.writeString(value);
    });

    writer.writeString(obj.bodyTemplate);
    writer.writeString(obj.stdoutPath);
    writer.writeString(obj.stderrPath);
    writer.writeString(obj.errorPath);
    writer.writeString(obj.executionTimePath);
    writer.writeString(obj.memoryPath);
    writer.writeBool(obj.isReadOnly);
  }
}
