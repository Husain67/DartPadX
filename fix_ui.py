import os

# Add format button to toolbar
with open('lib/ui/widgets/toolbar.dart', 'r') as f:
    content = f.read()

import_format = "import 'package:dart_style/dart_style.dart';\n"
if import_format not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_format)

format_btn = """
          _ToolbarBtn(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: activeFile == null ? null : () => _handleFormat(context, ref, activeFile.content),
          ),
"""
content = content.replace("          _ToolbarBtn(\n            icon: Icons.copy", format_btn + "          _ToolbarBtn(\n            icon: Icons.copy")

format_func = """
  void _handleFormat(BuildContext context, WidgetRef ref, String content) {
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(content);
      onCodeImported(formatted);
      _showToast('Code formatted');
    } catch (e) {
      _showToast('Format error: Invalid Dart syntax');
    }
  }
"""
content = content.replace("  Future<void> _handleCopy", format_func + "\n  Future<void> _handleCopy")

with open('lib/ui/widgets/toolbar.dart', 'w') as f:
    f.write(content)

# Add Replit, CodeX, HackerEarth to presets
with open('lib/providers/app_state.dart', 'r') as f:
    content = f.read()

missing_presets = """
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'Replit',
          endpoint: '',
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
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'CodeX',
          endpoint: '',
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
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'HackerEarth',
          endpoint: '',
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
"""
content = content.replace("        CompilerPreset(\n          id: const Uuid().v4(),\n          name: 'Blank',", missing_presets + "        CompilerPreset(\n          id: const Uuid().v4(),\n          name: 'Blank',")
with open('lib/providers/app_state.dart', 'w') as f:
    f.write(content)

# Show memory in output sheet
with open('lib/ui/widgets/output_sheet.dart', 'r') as f:
    content = f.read()

memory_ui = """
                        if (execState.executionTime.isNotEmpty) ...[
                          Text('${execState.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        if (execState.memory.isNotEmpty) ...[
                          Text('${execState.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
"""
content = content.replace("                        if (execState.executionTime.isNotEmpty) ...[\n                          Text('${execState.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),\n                          const SizedBox(width: 8),\n                        ],", memory_ui)
with open('lib/ui/widgets/output_sheet.dart', 'w') as f:
    f.write(content)

# Update main screen _syncEditorWithState for formatting (need to fully replace code instead of appending)
with open('lib/ui/screens/main_screen.dart', 'r') as f:
    content = f.read()

# Wait, the toolbar uses `onCodeImported`. If we use it for formatting, we need to pass a flag or replace it.
# Actually, the toolbar passes the entire formatted code, but the `onCodeImported` in main_screen logic is:
#                        if (cursor >= 0) {
#                            final current = _codeController!.text;
#                            final updated = current.substring(0, cursor) + code + current.substring(cursor);
# ... this appends code, which breaks formatting. We need to distinguish between Paste/Import vs Format.
