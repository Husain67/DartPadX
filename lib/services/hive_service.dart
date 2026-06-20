import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';
  static const String currentFileIdKey = 'currentFileId';
  static const String currentPresetIdKey = 'currentPresetId';

  late Box<FileModel> filesBox;
  late Box<CompilerPreset> presetsBox;
  late SharedPreferences prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    filesBox = await Hive.openBox<FileModel>(filesBoxName);
    presetsBox = await Hive.openBox<CompilerPreset>(presetsBoxName);
    prefs = await SharedPreferences.getInstance();

    await _initDefaults();
  }

  Future<void> _initDefaults() async {
    if (filesBox.isEmpty) {
      final defaultFile = FileModel(
        id: '1',
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Welcome to DartMini IDE!');

  // Example of reading input
  // print('Enter your name:');
  // String? name = stdin.readLineSync();
  // print('Hello, \$name!');
}
''',
        lastModified: DateTime.now(),
      );
      await filesBox.put(defaultFile.id, defaultFile);
      await prefs.setString(currentFileIdKey, defaultFile.id);
    }

    if (presetsBox.isEmpty) {
      final presets = [
        CompilerPreset(
          id: 'onecompiler',
          name: 'OneCompiler (Default)',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          headers: {
            'x-rapidapi-key': const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
            'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
            'Content-Type': 'application/json'
          },
          queryParams: {},
          requestBodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "index.dart",
      "content": "{code}"
    }
  ]
}''',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '',
          isDefault: true,
        ),
        CompilerPreset(
          id: 'jdoodle',
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '''{
  "script": "{code}",
  "language": "dart",
  "versionIndex": "0",
  "clientId": "{YOUR_CLIENT_ID}",
  "clientSecret": "{YOUR_CLIENT_SECRET}",
  "stdin": "{stdin}"
}''',
          stdoutPath: 'output',
          stderrPath: '',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
          isDefault: false,
        ),
        CompilerPreset(
          id: 'piston',
          name: 'Piston',
          endpointUrl: 'https://emacs.ch/api/v2/execute',
          httpMethod: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '''{
  "language": "dart",
  "version": "*",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ],
  "stdin": "{stdin}"
}''',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        ),
        CompilerPreset(
          id: 'replit',
          name: 'Replit',
          endpointUrl: 'https://example.com/replit',
          httpMethod: 'POST',
          authType: 'None',
          headers: {},
          queryParams: {},
          requestBodyTemplate: '{}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        ),
        CompilerPreset(
          id: 'codex',
          name: 'CodeX',
          endpointUrl: 'https://api.codex.jaagrav.in',
          httpMethod: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '''{
  "code": "{code}",
  "language": "dart",
  "input": "{stdin}"
}''',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        ),
        CompilerPreset(
          id: 'hackerearth',
          name: 'HackerEarth',
          endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          headers: {'client-secret': '{YOUR_CLIENT_SECRET}', 'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '''{
  "lang": "DART",
  "source": "{code}",
  "input": "{stdin}"
}''',
          stdoutPath: 'result.run_status.output',
          stderrPath: 'result.run_status.stderr',
          errorPath: 'errors',
          executionTimePath: 'result.run_status.time_used',
          memoryPath: 'result.run_status.memory_used',
          isDefault: false,
        ),
        CompilerPreset(
          id: 'blank',
          name: 'Blank',
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
          isDefault: false,
        )
      ];

      for (var preset in presets) {
        await presetsBox.put(preset.id, preset);
      }
      await prefs.setString(currentPresetIdKey, 'onecompiler');
    }
  }
}
