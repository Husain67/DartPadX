import re

with open('lib/src/features/editor/presentation/main_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports = """import 'package:dartmini_ide/src/features/editor/presentation/output_sheet.dart';
import 'package:dartmini_ide/src/features/editor/utils/file_actions.dart';
import 'package:flutter/services.dart';
"""
content = re.sub(r"(import 'package:flutter/material\.dart';)", r"\1\n" + imports, content)

# Replace output sheet placeholder
content = content.replace(
    "const Positioned(\n                    bottom: 0,\n                    left: 0,\n                    right: 0,\n                    child: SizedBox(height: 50, child: Center(child: Text('Output Sheet Placeholder'))),\n                  ),",
    "const Positioned(\n                    bottom: 0,\n                    left: 0,\n                    right: 0,\n                    child: OutputSheet(),\n                  ),"
)

# Update Run button logic
run_logic = """{
        final activeFile = ref.read(fileProvider).activeFile;
        if (activeFile != null) {
           ref.read(executionProvider.notifier).runCode(activeFile.content);
        }
      }"""
content = re.sub(r"onPressed: executionState\.isRunning \? null : \(\) \{\s*// Trigger run logic\s*\},",
                 f"onPressed: executionState.isRunning ? null : () {run_logic},", content)

# Update toolbar buttons actions
toolbar_actions = """
          ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onPressed: () => ref.read(fileProvider.notifier).createFile(),
          ),
          ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onPressed: () async {
               final data = await FileActions.importFile();
               if (data != null) {
                 ref.read(fileProvider.notifier).importFile(data['name']!, data['content']!);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 FileActions.copyToClipboard(activeFile.content);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onPressed: () async {
               final text = await FileActions.pasteFromClipboard();
               if (text != null) {
                 ref.read(fileProvider.notifier).updateActiveFileContent(text);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 FileActions.downloadFile(activeFile);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 FileActions.shareFile(activeFile);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onPressed: () async {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile == null) return;

               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text('Delete File?'),
                   content: const Text('This cannot be undone.'),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, false),
                       child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                     ),
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, true),
                       child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                     ),
                   ],
                 )
               );

               if (confirm == true && mounted) {
                 ref.read(fileProvider.notifier).deleteActiveFile();
               }
            },
          ),
"""
# Replace the middle part of toolbar
content = re.sub(
    r"ToolbarButton\(\s*icon: Icons\.add,\s*label: 'New File',\s*onPressed: \(\) => ref\.read\(fileProvider\.notifier\)\.createFile\(\),\s*\),.*?ToolbarButton\(\s*icon: Icons\.delete,\s*label: 'Delete',\s*onPressed: \(\) \{\},\s*\),",
    toolbar_actions,
    content,
    flags=re.DOTALL
)

with open('lib/src/features/editor/presentation/main_screen.dart', 'w') as f:
    f.write(content)
