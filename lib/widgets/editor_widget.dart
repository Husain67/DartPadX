import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/editor_provider.dart';
import '../theme/app_theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String _lastActiveId = '';
  bool _isUpdating = false;

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
    if (_isUpdating || _controller == null) return;

    // Prevent state updates while building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).updateActiveFileContent(_controller!.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);

    if (!editorState.isReady || editorState.activeFile == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent));
    }

    final activeFile = editorState.activeFile!;

    if (_lastActiveId != activeFile.id) {
      _lastActiveId = activeFile.id;
      _initController(activeFile.content);
    } else if (_controller != null && _controller!.text != activeFile.content && !_isUpdating) {
      // Content updated externally (e.g. format, paste)
      _isUpdating = true;
      _controller!.text = activeFile.content;
      _isUpdating = false;
    }

    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          color: Colors.black26,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: editorState.files.length,
            itemBuilder: (context, index) {
              final file = editorState.files[index];
              final isActive = file.id == activeFile.id;
              return GestureDetector(
                onTap: () => ref.read(editorProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white10 : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      if (isActive && editorState.files.length > 1) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete this file?'),
                                content: Text('Are you sure you want to delete ${file.name}? This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(editorProvider.notifier).deleteActiveFile();
                            }
                          },
                          child: const Icon(Icons.close, size: 16, color: Colors.white54),
                        ),
                      ]
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
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(
                    color: Colors.white38,
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
