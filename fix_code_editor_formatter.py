import re

with open('lib/src/features/editor/presentation/main_screen.dart', 'r') as f:
    content = f.read()

imports = "import 'package:dart_style/dart_style.dart';\n"
content = re.sub(r"(import 'package:flutter/material\.dart';)", r"\1\n" + imports, content)

formatter_logic = """
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 try {
                   final formatter = DartFormatter();
                   final formatted = formatter.format(activeFile.content);
                   ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                   // force a state update so code_editor_widget resyncs
                   ref.read(fileProvider.notifier).setActiveFile(activeFile.id);
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format error: $e')));
                 }
               }
            },
"""

content = re.sub(
    r"onPressed: \(\) \{\s*// Placeholder for dart formatter\s*// In a real app we would use dart_style package here\s*\},",
    formatter_logic,
    content
)

with open('lib/src/features/editor/presentation/main_screen.dart', 'w') as f:
    f.write(content)
