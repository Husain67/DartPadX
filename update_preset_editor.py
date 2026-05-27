import re

with open('lib/src/features/settings/presentation/preset_editor.dart', 'r') as f:
    content = f.read()

imports = "import 'package:dartmini_ide/src/features/settings/presentation/test_connection_dialog.dart';\n"
content = re.sub(r"(import 'package:flutter/material\.dart';)", r"\1\n" + imports, content)

test_btn = """
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final tempPreset = CompilerPreset(
                    id: widget.preset?.id ?? const Uuid().v4(),
                    name: _nameController.text,
                    endpointUrl: _urlController.text,
                    httpMethod: _httpMethod,
                    authType: _authType,
                    headers: Map.fromEntries(_headers),
                    queryParams: Map.fromEntries(_queryParams),
                    requestBodyTemplate: _bodyController.text,
                    stdoutPath: _stdoutController.text,
                    stderrPath: _stderrController.text,
                    errorPath: _errorController.text,
                    executionTimePath: _timeController.text,
                    memoryPath: _memController.text,
                  );
                  showDialog(
                    context: context,
                    builder: (context) => TestConnectionDialog(preset: tempPreset),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 32),
"""

content = content.replace("const SizedBox(height: 32),\n          ],\n        ),\n      ),\n    );\n  }\n}", test_btn + "          ],\n        ),\n      ),\n    );\n  }\n}")

with open('lib/src/features/settings/presentation/preset_editor.dart', 'w') as f:
    f.write(content)
