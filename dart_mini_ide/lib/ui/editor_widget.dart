import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _controller;

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
    ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
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
    final activeFile = fileState.activeFile;

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFile != null && next.activeFileId != previous?.activeFileId) {
        if (_controller.text != next.activeFile!.content) {
          _controller.text = next.activeFile!.content;
        }
      }
    });

    if (activeFile == null) {
      return const Center(child: Text('No file open', style: TextStyle(color: Colors.white54)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabBar(fileState),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  margin: 8.0,
                  textStyle: TextStyle(color: Colors.white54),
                ),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                background: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(FileState fileState) {
    return Container(
      height: 40,
      color: const Color(0xFF111111),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: fileState.files.map((file) {
            final isActive = file.id == fileState.activeFileId;
            return GestureDetector(
              onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1a1a1a) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Switch back to file first if it's not active, or just delete if it is.
                        // For simplicity, we just set active and delete.
                        ref.read(fileProvider.notifier).setActiveFile(file.id);
                        ref.read(fileProvider.notifier).deleteActiveFile();
                      },
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isActive ? Colors.white70 : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
