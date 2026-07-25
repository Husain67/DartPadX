import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String? _currentFileId;
  bool _isInternalUpdate = false;

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
    if (_isInternalUpdate || _currentFileId == null || _controller == null)
      return;

    // Check if the actual content changed, not just cursor position
    final currentContent = ref.read(fileProvider.notifier).activeFile?.content;
    if (currentContent != _controller!.text) {
      ref
          .read(fileProvider.notifier)
          .updateActiveFileContent(_controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = ref.read(fileProvider.notifier).activeFile;

    if (activeFile == null) {
      return const Center(
          child: Text("No files open", style: TextStyle(color: Colors.grey)));
    }

    // Initialize or switch files
    if (_currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      _initController(activeFile.content);
    } else {
      // If external state updated the content (e.g., paste button), sync it
      if (_controller != null && _controller!.text != activeFile.content) {
        _isInternalUpdate = true;
        _controller!.text = activeFile.content;
        _isInternalUpdate = false;
      }
    }

    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          color: Colors.black,
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
                    color:
                        isActive ? AppTheme.backgroundEnd : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive
                            ? AppTheme.primaryAccent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file,
                          size: 14,
                          color:
                              isActive ? AppTheme.primaryAccent : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (fileState.files.length > 1)
                        InkWell(
                          onTap: () {
                            ref.read(fileProvider.notifier).deleteFile(file.id);
                          },
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.grey),
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
                gutterStyle: GutterStyle(
                  textStyle: const TextStyle(height: 1.5, color: Colors.grey),
                  background: AppTheme.backgroundStart,
                  margin: 8.0,
                ),
                textStyle:
                    const TextStyle(fontFamily: 'monospace', fontSize: 14),
                expands: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
