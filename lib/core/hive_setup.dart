import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

class HiveSetup {
  static const String filesBoxName = 'files_box';
  static const String presetsBoxName = 'presets_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<FileModel>(filesBoxName);
    final presetBox = await Hive.openBox<CompilerPreset>(presetsBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);

    if (presetBox.isEmpty) {
      _populateDefaultPresets(presetBox);
    }

    final fileBox = Hive.box<FileModel>(filesBoxName);
    if (fileBox.isEmpty) {
      _populateDefaultFiles(fileBox);
    }
  }

  static void _populateDefaultFiles(Box<FileModel> box) {
    const uuid = Uuid();
    final file = FileModel(
      id: uuid.v4(),
      name: 'main.dart',
      content: '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Welcome, \${name ?? "Guest"}!');
}
''',
    );
    box.put(file.id, file);
  }

  static void _populateDefaultPresets(Box<CompilerPreset> box) {
    final presets = [
      CompilerPreset(
        id: 'preset_onecompiler',
        platformName: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'X-Rapidapi-Key': const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: ''),
          'Content-Type': 'application/json'
        },
        queryParams: {},
        requestBodyTemplate: '{"language":"dart","stdin":"{stdin}","files":[{"name":"main.dart","content":"{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isDefault: true,
      ),
      CompilerPreset(
        id: 'preset_jdoodle',
        platformName: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId":"YOUR_CLIENT_ID","clientSecret":"YOUR_CLIENT_SECRET","script":"{code}","stdin":"{stdin}","language":"dart","versionIndex":"4"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: 'preset_piston',
        platformName: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language":"dart","version":"*","files":[{"content":"{code}"}],"stdin":"{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: 'preset_replit',
        platformName: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: 'preset_codex',
        platformName: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code":"{code}","language":"dart","input":"{stdin}"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: 'preset_hackerearth',
        platformName: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'client-secret': 'YOUR_API_KEY', 'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"source":"{code}","lang":"DART","input":"{stdin}"}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'errors',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: 'preset_blank',
        platformName: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];

    for (var preset in presets) {
      box.put(preset.id, preset);
    }
  }
}
