import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../core/theme.dart';

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

    _controller.addListener(() {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        if (previous != null) {
          ref.read(fileProvider.notifier).forceSaveActiveFile();
        }
        if (next.activeFile != null && _controller.text != next.activeFile!.content) {
          _controller.text = next.activeFile!.content;
        }
      } else if (next.activeFile != null && _controller.text != next.activeFile!.content) {
          // This allows programmatic updates (like formatting/pasting) to sync to controller
          final currentCursor = _controller.selection;
          _controller.text = next.activeFile!.content;

          // attempt to restore cursor if valid
          if (currentCursor.baseOffset <= _controller.text.length && currentCursor.extentOffset <= _controller.text.length) {
              _controller.selection = currentCursor;
          }
      }
    });

    if (activeFile == null) {
      return const Center(child: Text('No file opened'));
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
                onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.surfaceColor : AppTheme.backgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
                      const SizedBox(width: 8),
                      if (fileState.files.length > 1)
                        GestureDetector(
                          onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
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
            data: CodeThemeData(styles: draculaTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
