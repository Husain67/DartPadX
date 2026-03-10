import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../models/code_file.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController controller;
  String? currentFileId;

  @override
  void initState() {
    super.initState();
    controller = CodeController(
      text: '',
      language: dart,
    );
    controller.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && controller.text != activeFile.content) {
      ref.read(fileProvider.notifier).updateActiveFileContent(controller.text);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _syncControllerWithState() {
    final activeFile = ref.watch(fileProvider).activeFile;
    if (activeFile != null) {
      if (activeFile.id != currentFileId) {
        // Switched to a new file tab, fully update text and id
        currentFileId = activeFile.id;
        controller.text = activeFile.content;
      } else {
         // Same file, check if content changed externally (e.g. format, paste from toolbar)
         if (controller.text != activeFile.content) {
             final cursorPosition = controller.selection.baseOffset;
             controller.text = activeFile.content;
             // Try to restore cursor safely
             if (cursorPosition >= 0 && cursorPosition <= controller.text.length) {
                controller.selection = TextSelection.collapsed(offset: cursorPosition);
             } else {
                controller.selection = TextSelection.collapsed(offset: controller.text.length);
             }
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncControllerWithState();
    final fileState = ref.watch(fileProvider);

    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          color: Colors.black26,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = index == fileState.activeIndex;
              return GestureDetector(
                onTap: () {
                  ref.read(fileProvider.notifier).setActiveIndex(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.backgroundEnd : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? AppTheme.primaryAccent : Colors.white70,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          ref.read(fileProvider.notifier).deleteFileById(file.id);
                        },
                        child: Icon(Icons.close, size: 14, color: isActive ? AppTheme.primaryAccent : Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Editor
        Expanded(
          child: Focus(
             onKey: (node, event) {
                if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
                   // Force save trigger is automatic via debounce, but we could explicitly format here if desired
                   return KeyEventResult.handled;
                }
                if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyR) {
                   ref.read(executionProvider.notifier).executeCode();
                   return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
             },
             child: CodeTheme(
               data: CodeThemeData(styles: atomOneDarkTheme),
               child: SingleChildScrollView(
                 child: CodeField(
                   controller: controller,
                   textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                   gutterStyle: const GutterStyle(
                     textStyle: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                     showLineNumbers: true,
                     width: 48,
                     margin: 4,
                   ),
                 ),
               ),
             ),
          ),
        ),
      ],
    );
  }
}
