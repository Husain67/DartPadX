import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';
import '../core/constants.dart';

class HiveService {
  static const String filesBoxName = 'files_box';
  static const String presetsBoxName = 'presets_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CodeFileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CompilerPresetAdapter());
    }

    // Open boxes
    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
    await Hive.openBox(settingsBoxName);

    // Seed initial data if empty
    await _seedInitialData();
  }

  static Future<void> _seedInitialData() async {
    final filesBox = Hive.box<CodeFile>(filesBoxName);
    if (filesBox.isEmpty) {
      final defaultFile = CodeFile(
        name: AppConstants.defaultFileName,
        content: AppConstants.defaultDartCode,
      );
      await filesBox.put(defaultFile.id, defaultFile);
    }

    final presetsBox = Hive.box<CompilerPreset>(presetsBoxName);
    if (presetsBox.isEmpty) {
      final defaultPresets = _getBuiltInPresets();
      for (var preset in defaultPresets) {
        await presetsBox.put(preset.id, preset);
      }
    }
  }

  static List<CompilerPreset> _getBuiltInPresets() {
    return [
      CompilerPreset(
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'X-RapidAPI-Key': '{api_key}',
          'Content-Type': 'application/json',
        },
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isBuiltIn: true,
      ),
      CompilerPreset(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None', // Uses body params for auth
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"clientId": "{client_id}", "clientSecret": "{client_secret}", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isBuiltIn: true,
      ),
      CompilerPreset(
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        isBuiltIn: true,
      ),
      CompilerPreset(
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"code": "{code}", "language": "dart", "stdin": "{stdin}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        isBuiltIn: true,
      ),
      CompilerPreset(
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        isBuiltIn: true,
      ),
      CompilerPreset(
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'client-secret': '{api_key}', 'Content-Type': 'application/json'},
        requestBodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
        isBuiltIn: true,
      ),
      CompilerPreset(
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        isBuiltIn: true,
      ),
    ];
  }
}
