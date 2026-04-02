import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
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
  String? _boundFileId;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String id, String content) {
    if (_controller != null) {
      _controller!.dispose();
    }
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _boundFileId = id;

    _controller!.addListener(() {
      if (_boundFileId != null && _controller != null) {
        ref.read(filesProvider.notifier).updateContent(_boundFileId!, _controller!.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilesState>(filesProvider, (previous, next) {
      // Re-init controller if the active file changed
      if (next.activeFileId != null && next.activeFileId != _boundFileId) {
        setState(() {
          _initController(next.activeFileId!, next.activeFile!.content);
        });
      }
    });

    final filesState = ref.watch(filesProvider);

    if (filesState.files.isEmpty || filesState.activeFileId == null) {
      return const Center(child: Text('No file opened'));
    }

    if (_controller == null || _boundFileId != filesState.activeFileId) {
      _initController(filesState.activeFileId!, filesState.activeFile!.content);
    }

    return Column(
      children: [
        // File Tabs
        Container(
          height: 40,
          color: AppColors.surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filesState.files.length,
            itemBuilder: (context, index) {
              final file = filesState.files[index];
              final isActive = file.id == filesState.activeFileId;

              return GestureDetector(
                onTap: () => ref.read(filesProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.backgroundStart : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppColors.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(filesProvider.notifier).deleteFile(file.id),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isActive ? Colors.white : AppColors.textSecondary,
                        ),
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
                controller: _controller!,
                gutterStyle: const GutterStyle(showLineNumbers: true),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
