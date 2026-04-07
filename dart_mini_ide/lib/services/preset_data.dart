import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class PresetData {
  static List<CompilerPreset> getPreloadedPresets() {
    const uuid = Uuid();
    return [
      CompilerPreset(
        id: uuid.v4(),
        name: 'OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: 'X-RapidAPI-Key: YOUR_API_KEY',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        queryParams: {},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        timePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        timePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Piston',
        url: 'https://emacs.ch/api/v2/execute', // Example public piston instance
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"language": "dart", "version": "3.0.2", "files": [{"content": "{code}"}]}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: '',
        timePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Blank',
        url: 'https://',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        timePath: '',
        memoryPath: '',
      ),
    ];
  }
}
