import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveStorageService {
  static const String filesBoxName = 'files_box';
  static const String presetsBoxName = 'presets_box';

  static final List<CompilerPreset> _defaultPresets = [
    CompilerPreset(
      name: 'OneCompiler (Dart)',
      url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      method: 'POST',
      authType: 'API-Key Header',
      authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      headers: {
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
      },
      bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      mappings: {
        'stdout': 'stdout',
        'stderr': 'stderr',
        'error': 'exception',
        'executionTime': 'executionTime',
        'memory': 'memory',
      },
    ),
    CompilerPreset(
      name: 'Piston (Dart)',
      url: 'https://emkc.org/api/v2/piston/execute',
      method: 'POST',
      bodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
      mappings: {
        'stdout': 'run.stdout',
        'stderr': 'run.stderr',
        'error': 'message',
        'executionTime': '',
        'memory': '',
      },
    ),
  ];

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);

    final filesBox = Hive.box<CodeFile>(filesBoxName);
    if (filesBox.isEmpty) {
      final initialFile = CodeFile(
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
      );
      await filesBox.put(initialFile.id, initialFile);
    }

    final presetsBox = Hive.box<CompilerPreset>(presetsBoxName);
    if (presetsBox.isEmpty) {
      for (var preset in _defaultPresets) {
        await presetsBox.put(preset.id, preset);
      }
    }
  }

  static Box<CodeFile> get filesBox => Hive.box<CodeFile>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
}
