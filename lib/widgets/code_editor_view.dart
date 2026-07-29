import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../theme.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({super.key});

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  CodeController? _controller;
  String? _currentFileId;
  bool _isInternalUpdate = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content, String fileId) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _currentFileId = fileId;

    _controller!.addListener(() {
      if (!_isInternalUpdate && _currentFileId != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text("No files open", style: TextStyle(color: Colors.white54)));
    }

    if (_controller == null || _currentFileId != activeFile.id) {
      _initController(activeFile.content, activeFile.id);
    } else if (_controller!.text != activeFile.content) {
      _isInternalUpdate = true;
      _controller!.text = activeFile.content;
      _isInternalUpdate = false;
    }

    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          decoration: BoxDecoration(
             border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
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
                    color: isActive ? AppTheme.gradientEnd : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      )
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name + (file.isSaved ? '' : ' *'),
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
                         child: const Icon(Icons.close, size: 16, color: Colors.white54),
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
            data: CodeThemeData(styles: darculaTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller!,
                textStyle: const TextStyle(fontFamily: 'monospace'),
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(
                    color: Colors.white54,
                    height: 1.5,
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
