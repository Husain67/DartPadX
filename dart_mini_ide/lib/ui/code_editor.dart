import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  String? _currentActiveId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_currentActiveId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = ref.read(fileProvider.notifier).activeFile;

    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId) {
        _currentActiveId = next.activeFileId;
        final nextActiveFile = ref.read(fileProvider.notifier).activeFile;
        if (nextActiveFile != null && _controller.text != nextActiveFile.content) {
          _controller.text = nextActiveFile.content;
        }
      } else if (next.activeFileId == _currentActiveId) {
        // Handle external content updates like paste/format
        final currentFile = ref.read(fileProvider.notifier).activeFile;
        if (currentFile != null && _controller.text != currentFile.content) {
          final cursorPosition = _controller.selection;
          _controller.text = currentFile.content;
          if (cursorPosition.baseOffset <= currentFile.content.length) {
            _controller.selection = cursorPosition;
          }
        }
      }
    });

    if (activeFile == null) {
      return const Center(child: Text('No file open'));
    }

    return Column(
      children: [
        // File Tabs
        Container(
          height: 40,
          color: const Color(0xFF1A1A1A),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == fileState.activeFileId;
              return GestureDetector(
                onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      if (fileState.files.length > 1) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (isActive) {
                               _currentActiveId = null; // reset to avoid sync issues
                            }
                            ref.read(fileProvider.notifier).deleteFileById(file.id);
                          },
                          child: const Icon(Icons.close, size: 14, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Editor
        Expanded(
          child: Container(
            color: const Color(0xFF050505),
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  gutterStyle: const GutterStyle(
                    showLineNumbers: true,
                    textStyle: TextStyle(color: Colors.grey, fontSize: 14),
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
