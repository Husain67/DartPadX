import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';


import '../providers/file_provider.dart';
import 'theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String _currentFileId = '';
  bool _isUpdatingFromState = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _controller!.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_isUpdatingFromState || _controller == null) return;
    ref.read(fileProvider.notifier).updateContent(_currentFileId, _controller!.text);
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text("No files open", style: TextStyle(color: Colors.white54)));
    }

    // Switch or init controller
    if (_currentFileId != activeFile.id || _controller == null) {
      _currentFileId = activeFile.id;
      _isUpdatingFromState = true;
      _initController(activeFile.content);
      _isUpdatingFromState = false;
    } else if (_controller!.text != activeFile.content) {
      // Content updated from outside (e.g. paste from toolbar)
      _isUpdatingFromState = true;
      _controller!.text = activeFile.content;
      _isUpdatingFromState = false;
    }

    return Column(
      children: [
        // Tabs
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == fileState.activeFileId;
              return GestureDetector(
                onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.backgroundEnd : Colors.black26,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                      right: const BorderSide(color: Colors.white12, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 13)),
                      const SizedBox(width: 8),
                      if (fileState.files.length > 1)
                        GestureDetector(
                          onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                          child: Icon(Icons.close, size: 14, color: isActive ? Colors.white70 : Colors.white38),
                        )
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
            data: CodeThemeData(styles: darculaTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller!,
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(color: Colors.white38, fontSize: 12),
                  showLineNumbers: true,
                  showErrors: false,
                  showFoldingHandles: false,
                ),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                expands: false,
                wrap: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
