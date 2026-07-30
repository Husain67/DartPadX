import 'dart:convert';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class CodeFile {
  final String id;
  String name;
  String content;

  CodeFile({
    String? id,
    required this.name,
    required this.content,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
    };
  }

  factory CodeFile.fromJson(Map<String, dynamic> json) {
    return CodeFile(
      id: json['id'] as String?,
      name: json['name'] as String,
      content: json['content'] as String,
    );
  }
}

class CompilerPreset {
  final String id;
  String name;
  String endpoint;
  String method; // GET, POST, PUT
  String authType; // None, API-Key Header, Bearer Token, Basic Auth, Query Param
  Map<String, String> headers;
  Map<String, String> queryParams;
  String requestBodyTemplate; // JSON with placeholders {code}, {stdin}, {language}
  Map<String, String> responseMapping; // path mapping for stdout, stderr, etc.

  CompilerPreset({
    String? id,
    required this.name,
    required this.endpoint,
    this.method = 'POST',
    this.authType = 'None',
    this.headers = const {},
    this.queryParams = const {},
    this.requestBodyTemplate = '',
    this.responseMapping = const {},
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'method': method,
      'authType': authType,
      'headers': headers,
      'queryParams': queryParams,
      'requestBodyTemplate': requestBodyTemplate,
      'responseMapping': responseMapping,
    };
  }

  factory CompilerPreset.fromJson(Map<String, dynamic> json) {
    return CompilerPreset(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unnamed',
      endpoint: json['endpoint'] as String? ?? '',
      method: json['method'] as String? ?? 'POST',
      authType: json['authType'] as String? ?? 'None',
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
      requestBodyTemplate: json['requestBodyTemplate'] as String? ?? '',
      responseMapping: Map<String, String>.from(json['responseMapping'] as Map? ?? {}),
    );
  }
}
