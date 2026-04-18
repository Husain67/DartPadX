import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../theme/app_theme.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({super.key});

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  CodeController? _codeController;
  String? _lastActiveId;

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  void _initController(String initialText) {
    _codeController = CodeController(
      text: initialText,
      language: dart,
    );
    _codeController!.addListener(() {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    // Synchronize controller with active file change
    if (activeFile != null && activeFile.id != _lastActiveId) {
      _lastActiveId = activeFile.id;
      if (_codeController == null) {
        _initController(activeFile.content);
      } else {
        _codeController!.text = activeFile.content;
      }
    }

    return Column(
      children: [
        // File Tabs
        Container(
          height: 40,
          color: Colors.black45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == fileState.activeFileId;
              return GestureDetector(
                onTap: () {
                  ref.read(fileProvider.notifier).setActiveFile(file.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.surfaceColor : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.accentYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white54,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          ref.read(fileProvider.notifier).deleteFileById(file.id);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isActive ? Colors.white : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Code Editor
        Expanded(
          child: activeFile == null
              ? const Center(child: Text("No files open", style: TextStyle(color: Colors.white54)))
              : CodeTheme(
                  data: CodeThemeData(styles: monokaiSublimeTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _codeController!,
                      gutterStyle: const GutterStyle(
                        showLineNumbers: true,
                        textStyle: TextStyle(color: Colors.white38),
                      ),
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
