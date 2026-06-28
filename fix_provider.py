with open("dartmini_ide/lib/providers/compiler_provider.dart", "r") as f:
    content = f.read()

replacement = """
    if (presets.isEmpty) {
      // Add a default preset as an example for users
      final myCustom = CompilerPreset(
        name: 'My Custom API',
        endpointUrl: 'https://api.example.com/execute',
        httpMethod: 'POST',
        stdoutPath: 'data.output',
        stderrPath: 'data.error',
      );

      final piston = CompilerPreset(
        name: 'Piston (Emulated)',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '''{
  "language": "{language}",
  "version": "*",
  "files": [{"content": "{code}"}],
  "stdin": "{stdin}"
}''',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
      );

      final jdoodle = CompilerPreset(
        name: 'JDoodle (Requires Client ID/Secret in body)',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '''{
  "script": "{code}",
  "language": "dart",
  "versionIndex": "0",
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET"
}''',
        stdoutPath: 'output',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      );

      final codex = CompilerPreset(
        name: 'CodeX API',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        requestBodyTemplate: 'code={code}&language=dart',
        stdoutPath: 'output',
        errorPath: 'error',
      );

      for (var p in [myCustom, piston, jdoodle, codex]) {
         _presetBox.put(p.id, p);
         presets.add(p);
      }
    }
"""

import re
content = re.sub(r'    if \(presets\.isEmpty\) \{.*?\n    \}', replacement, content, flags=re.DOTALL)

with open("dartmini_ide/lib/providers/compiler_provider.dart", "w") as f:
    f.write(content)
