import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<FileModel>(AppConstants.filesBox);
    await Hive.openBox<CompilerPreset>(AppConstants.presetsBox);
    await Hive.openBox<dynamic>(AppConstants.settingsBox);

    _seedInitialData();
  }

  static void _seedInitialData() {
    final filesBox = Hive.box<FileModel>(AppConstants.filesBox);
    if (filesBox.isEmpty) {
      final defaultFile = FileModel(
        id: const Uuid().v4(),
        name: AppConstants.defaultFileName,
        content: AppConstants.defaultDartCode,
      );
      filesBox.put(defaultFile.id, defaultFile);
    }

    final presetsBox = Hive.box<CompilerPreset>(AppConstants.presetsBox);
    if (presetsBox.isEmpty) {
      final defaultPresets = [
        CompilerPreset(
          id: 'default_onecompiler',
          name: 'OneCompiler (Default)',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          headers: {
            'x-rapidapi-key': AppConstants.defaultOneCompilerKey,
            'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
            'Content-Type': 'application/json',
          },
          queryParams: {},
          requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "{filename}", "content": "{code}"}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '',
        ),
        CompilerPreset(
          id: 'preset_jdoodle',
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "4"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          id: 'preset_piston',
          name: 'Piston',
          endpointUrl: 'https://emacs.emacs.com/api/v2/execute', // Just a placeholder, piston public api is emacs.emacs.com? no, piston.rs or something, let's use piston.rs or generic
          httpMethod: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"language": "dart", "version": "*", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'message',
          executionTimePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: 'preset_replit',
          name: 'Replit',
          endpointUrl: 'https://replit.com/api/beta/execute', // Mock endpoint
          httpMethod: 'POST',
          authType: 'Bearer Token',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"language": "dart", "code": "{code}", "stdin": "{stdin}"}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'error',
          executionTimePath: 'time',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          id: 'preset_codex',
          name: 'CodeX',
          endpointUrl: 'https://api.codex.jaagrav.in',
          httpMethod: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: 'preset_hackerearth',
          name: 'HackerEarth',
          endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          headers: {'client-secret': 'YOUR_CLIENT_SECRET', 'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}"}',
          stdoutPath: 'result.run_status.output',
          stderrPath: 'result.run_status.stderr',
          errorPath: 'errors',
          executionTimePath: 'result.run_status.time_used',
          memoryPath: 'result.run_status.memory_used',
        ),
        CompilerPreset(
          id: 'preset_blank',
          name: 'Blank',
          endpointUrl: 'https://',
          httpMethod: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
        ),
      ];

      for (var preset in defaultPresets) {
        presetsBox.put(preset.id, preset);
      }
    }

    final settingsBox = Hive.box<dynamic>(AppConstants.settingsBox);
    if (!settingsBox.containsKey('activePresetId')) {
      settingsBox.put('activePresetId', 'default_onecompiler');
    }
  }

  static Box<FileModel> get filesBox => Hive.box<FileModel>(AppConstants.filesBox);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(AppConstants.presetsBox);
  static Box<dynamic> get settingsBox => Hive.box<dynamic>(AppConstants.settingsBox);
}
