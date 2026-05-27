import re

with open('lib/src/features/settings/providers/compiler_provider.dart', 'r') as f:
    content = f.read()

preloaded = """
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "code": "{code}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_CLIENT_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{"lang": "DART", "source": "{code}", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'errors',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
        isPreloaded: true,
      ),
"""

content = content.replace(
    "// Add placeholders for others required by memory: JDoodle, Piston, Replit, CodeX, HackerEarth, Blank",
    preloaded
)

with open('lib/src/features/settings/providers/compiler_provider.dart', 'w') as f:
    f.write(content)
