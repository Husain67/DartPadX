import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({Key? key}) : super(key: key);

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
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.content != _controller.text) {
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
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId) {
        _currentActiveId = next.activeFileId;
        if (next.activeFile != null && next.activeFile!.content != _controller.text) {
          final pos = _controller.selection;
          _controller.text = next.activeFile!.content;
          if (pos.baseOffset <= _controller.text.length) {
            _controller.selection = pos;
          }
        }
      } else if (next.activeFile != null && next.activeFile!.content != _controller.text) {
        // Handle external updates like Format Code
        _controller.text = next.activeFile!.content;
      }
    });

    final fileState = ref.watch(fileProvider);

    if (fileState.files.isEmpty) {
      return const Center(child: Text('No open files.', style: TextStyle(color: Colors.white54)));
    }

    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          color: Colors.black.withValues(alpha: 0.3),
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
                    color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.white54)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                        child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.white54),
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
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
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
