import os
import re

def update_execution_provider():
    path = 'lib/providers/execution_provider.dart'
    with open(path, 'r') as f:
        content = f.read()

    # Fix 'apiKey' error. In fix_other_issues.py I used `final apiKey = String.fromCharCodes...` but maybe there was a typo left over.
    content = content.replace("final String.fromEnvironment", "")
    content = content.replace("final apiKey = const String.fromEnvironment('OC_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');", "")
    content = content.replace("final apiKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));",
                              "final apiKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));")
    # Actually I probably broke execution_provider last time by just string replacing incorrectly. Let's fully rewrite the `_runOneCompiler` method safely.

    match = re.search(r'Future<void> _runOneCompiler.*?\n  \}', content, re.DOTALL)
    if match:
        new_method = """Future<void> _runOneCompiler(String code) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    final apiKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'language': 'dart',
        'files': [
          {'name': 'main.dart', 'content': code}
        ]
      }),
    );

    _parseAndSetOutput(
      response.body,
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
    );
  }"""
        content = content[:match.start()] + new_method + content[match.end():]

    with open(path, 'w') as f:
        f.write(content)


def update_examples_gallery():
    path = 'lib/ui/examples_gallery.dart'
    with open(path, 'r') as f:
        content = f.read()

    # The issue: `final Map<String, String> examples = const {` with string interpolations inside (like $name).
    # Those were unescaped in python, let's just make it a non-const map.
    content = content.replace("final Map<String, String> examples = const {", "final Map<String, String> examples = {")
    with open(path, 'w') as f:
        f.write(content)

def fix_unused_imports_and_warnings():
    # lib/ui/editor_widget.dart
    path = 'lib/ui/editor_widget.dart'
    with open(path, 'r') as f:
        content = f.read()
    content = content.replace("import 'package:dart_style/dart_style.dart';\n", "")
    content = content.replace("import '../models/code_file.dart';\n", "")
    with open(path, 'w') as f:
        f.write(content)

    # lib/ui/main_screen.dart -> dart_style and path_provider are used in main_screen.dart so they shouldn't be unused... wait, I added them in main_screen but analyzer complained?
    # Ah, I added them at the top, but the file already had imports. Let's see if there are duplicates.
    path = 'lib/ui/main_screen.dart'
    with open(path, 'r') as f:
        content = f.read()
    if content.count("import 'package:dart_style/dart_style.dart';") > 1:
        content = content.replace("import 'package:dart_style/dart_style.dart';", "", 1)
    if content.count("import 'package:path_provider/path_provider.dart';") > 1:
        content = content.replace("import 'package:path_provider/path_provider.dart';", "", 1)
    with open(path, 'w') as f:
        f.write(content)

    # lib/ui/preset_editor_screen.dart
    path = 'lib/ui/preset_editor_screen.dart'
    with open(path, 'r') as f:
        content = f.read()
    content = content.replace("final bool _isNew = false;", "")
    content = content.replace("value: _editablePreset.httpMethod,", "initialValue: _editablePreset.httpMethod,")
    content = content.replace("value: _editablePreset.authType,", "initialValue: _editablePreset.authType,")
    content = content.replace("if (!mounted) return;", "")
    content = content.replace("showDialog(\n        context: context", "if (!mounted) return;\n      showDialog(\n        context: context")
    content = content.replace("ScaffoldMessenger.of(context).showSnackBar", "if (!mounted) return;\n      ScaffoldMessenger.of(context).showSnackBar")
    with open(path, 'w') as f:
        f.write(content)

    # lib/ui/settings_screen.dart
    path = 'lib/ui/settings_screen.dart'
    with open(path, 'r') as f:
        content = f.read()
    content = content.replace("activeColor: const Color(0xFFFACC15),", "activeThumbColor: const Color(0xFFFACC15),")
    with open(path, 'w') as f:
        f.write(content)


update_execution_provider()
update_examples_gallery()
fix_unused_imports_and_warnings()
