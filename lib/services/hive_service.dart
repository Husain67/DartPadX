import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String fileBoxName = 'files';
  static const String presetBoxName = 'presets';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>(fileBoxName);
    await Hive.openBox<CompilerPreset>(presetBoxName);
  }

  static Box<CodeFile> get fileBox => Hive.box<CodeFile>(fileBoxName);
  static Box<CompilerPreset> get presetBox => Hive.box<CompilerPreset>(presetBoxName);

  static List<CompilerPreset> getPreloadedPresets() {
    return [
      CompilerPreset(
        id: 'onecompiler',
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': '{authValue}',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        queryParams: {},
        bodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'piston',
        name: 'Piston (EngineerMan)',
        endpoint: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {
          'content-type': 'application/json',
        },
        queryParams: {},
        bodyTemplate: '{"language": "{language}", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None', // Uses body params usually, simplified here
        authValue: '',
        headers: {
          'content-type': 'application/json',
        },
        queryParams: {},
        bodyTemplate: '{"script": "{code}", "language": "{language}", "versionIndex": "0", "stdin": "{stdin}", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'blank',
        name: 'Blank Custom API',
        endpoint: 'https://api.example.com/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"code": "{code}"}',
        stdoutPath: 'data.stdout',
        stderrPath: 'data.stderr',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      )
    ];
  }
}
