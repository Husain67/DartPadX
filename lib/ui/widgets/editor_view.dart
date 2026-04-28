import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../theme/app_theme.dart';

class EditorView extends ConsumerStatefulWidget {
  const EditorView({super.key});

  @override
  ConsumerState<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends ConsumerState<EditorView> {
  CodeController? _controller;
  String _currentFileId = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
    _controller!.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_currentFileId.isNotEmpty && _controller != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      if (activeFile != null) {
        if (_currentFileId != activeFile.id) {
          _currentFileId = activeFile.id;
          _controller?.text = activeFile.content;
        } else if (_controller?.text != activeFile.content) {
          // Keep cursor position when content is updated externally (e.g. Paste/Format)
          final selection = _controller?.selection;
          _controller?.text = activeFile.content;
          if (selection != null && selection.baseOffset <= activeFile.content.length) {
            _controller?.selection = selection;
          }
        }
      } else {
        _currentFileId = '';
        _controller?.text = '';
      }
    });

    final fileState = ref.watch(fileProvider);

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
                onTap: () {
                  ref.read(fileProvider.notifier).setActiveFile(file.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? AppTheme.primaryAccent : Colors.white70,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            ref.read(fileProvider.notifier).deleteFile(file.id);
                          },
                          child: const Icon(Icons.close, size: 14, color: Colors.white70),
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
          child: _controller != null && fileState.activeFileId.isNotEmpty
              ? CodeTheme(
                  data: CodeThemeData(styles: atomOneDarkTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _controller!,
                      gutterStyle: const GutterStyle(showLineNumbers: true),
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                )
              : const Center(child: Text('No file opened', style: TextStyle(color: Colors.white54))),
        ),
      ],
    );
  }
}
