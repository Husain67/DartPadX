import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/preset_model.dart';
import '../core/constants.dart';

class HiveService {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<FileModel>(filesBoxName);
    var presetsBox = await Hive.openBox<CompilerPreset>(presetsBoxName);

    if (presetsBox.isEmpty) {
      _loadDefaultPresets(presetsBox);
    }
  }

  static void _loadDefaultPresets(Box<CompilerPreset> box) {
    final presets = [
      CompilerPreset(
        id: 'oc_default',
        name: 'OneCompiler',
        url: AppConstants.defaultOneCompilerUrl,
        method: 'POST',
        authType: 'None',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': AppConstants.defaultOneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        memoryPath: 'memory',
        executionTimePath: 'cpuTime',
      ),
      CompilerPreset(
        id: 'piston',
        name: 'Piston',
        url: 'https://emacs.ch/api/v2/execute', // Example public piston instance
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: 'replit',
        name: 'Replit',
        url: '',
        method: 'POST',
      ),
      CompilerPreset(
        id: 'codex',
        name: 'CodeX',
        url: '',
        method: 'POST',
      ),
      CompilerPreset(
        id: 'hackerearth',
        name: 'HackerEarth',
        url: '',
        method: 'POST',
      ),
      CompilerPreset(
        id: 'blank',
        name: 'Blank',
        url: '',
        method: 'POST',
      ),
    ];

    for (var preset in presets) {
      box.put(preset.id, preset);
    }
  }

  static Box<FileModel> get filesBox => Hive.box<FileModel>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
}
