import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class StorageService {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';
  final _uuid = const Uuid();

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());
    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);

    await _initDefaultFile();
    await _initDefaultPresets();
  }

  Future<void> _initDefaultFile() async {
    final box = Hive.box<CodeFile>(filesBoxName);
    if (box.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini!');
}''',
        lastModified: DateTime.now(),
      );
      await box.put(defaultFile.id, defaultFile);
    }
  }

  Future<void> _initDefaultPresets() async {
    final box = Hive.box<CompilerPreset>(presetsBoxName);
    if (box.isEmpty) {
      final presets = [
        CompilerPreset(
          id: _uuid.v4(),
          name: 'OneCompiler',
          endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          method: 'POST',
          authType: 'API-Key Header',
          authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          headers: {
            'content-type': 'application/json',
            'X-RapidAPI-Key': '{authValue}',
            'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
          },
          queryParams: {},
          bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
          mappings: {
            'stdout': 'stdout',
            'stderr': 'stderr',
            'error': 'exception',
            'executionTime': 'executionTime',
            'memory': 'memory'
          },
        ),
      ];
      for (var preset in presets) {
        await box.put(preset.id, preset);
      }
    }
  }

  Box<CodeFile> get filesBox => Hive.box<CodeFile>(filesBoxName);
  Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);

  List<CompilerPreset> getAllPresets() {
    return presetsBox.values.toList();
  }

  String exportPresetsAsJson() {
    final presets = getAllPresets().map((p) => {
      'id': p.id,
      'name': p.name,
      'endpoint': p.endpoint,
      'method': p.method,
      'authType': p.authType,
      'authValue': p.authValue,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'bodyTemplate': p.bodyTemplate,
      'mappings': p.mappings,
    }).toList();
    return jsonEncode(presets);
  }

  Future<void> importPresetsFromJson(String jsonString) async {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      for (var item in list) {
        final preset = CompilerPreset(
          id: item['id'] ?? _uuid.v4(),
          name: item['name'] ?? 'Imported Preset',
          endpoint: item['endpoint'] ?? '',
          method: item['method'] ?? 'POST',
          authType: item['authType'] ?? 'None',
          authValue: item['authValue'] ?? '',
          headers: Map<String, String>.from(item['headers'] ?? {}),
          queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
          bodyTemplate: item['bodyTemplate'] ?? '{}',
          mappings: Map<String, String>.from(item['mappings'] ?? {}),
        );
        await presetsBox.put(preset.id, preset);
      }
    } catch (e) {
      throw Exception('Failed to import presets: $e');
    }
  }
}
