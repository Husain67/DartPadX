import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../theme.dart';

class IDEEditor extends ConsumerStatefulWidget {
  const IDEEditor({super.key});

  @override
  ConsumerState<IDEEditor> createState() => _IDEEditorState();
}

class _IDEEditorState extends ConsumerState<IDEEditor> {
  late CodeController _codeController;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onTextChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_currentFileId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFileId != _currentFileId) {
        _currentFileId = next.activeFileId;
        if (next.activeFile != null && next.activeFile!.content != _codeController.text) {
          _codeController.text = next.activeFile!.content;
        }
      } else if (next.activeFile != null && next.activeFile!.content != _codeController.text) {
        // Handle cases where formatting or pasting updates state directly
        final cursorPosition = _codeController.selection.baseOffset;
        _codeController.text = next.activeFile!.content;
        if (cursorPosition >= 0 && cursorPosition <= _codeController.text.length) {
          _codeController.selection = TextSelection.collapsed(offset: cursorPosition);
        }
      }
    });

    final fileState = ref.watch(fileProvider);

    return Column(
      children: [
        // File Tabs
        Container(
          height: 40,
          color: Colors.black26,
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
                    color: isActive ? AppTheme.backgroundEnd : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.accentYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
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
                          ref.read(fileProvider.notifier).deleteFile(file.id);
                        },
                        child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.white54),
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
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  margin: 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
