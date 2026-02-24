import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key});

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize with current file content
    final currentFile = ref.read(currentFileProvider);
    _controller = CodeController(
      text: currentFile?.content ?? '',
      language: dart,
    );
    _controller.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final index = ref.read(currentFileIndexProvider);
    final currentFile = ref.read(currentFileProvider);
    if (currentFile != null && _controller.text != currentFile.content) {
       ref.read(fileProvider.notifier).updateFileContent(index, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for file index changes (switching tabs)
    ref.listen(currentFileIndexProvider, (previous, next) {
      if (previous != next) {
        final newFile = ref.read(fileProvider)[next];
        if (_controller.text != newFile.content) {
          _controller.text = newFile.content;
        }
      }
    });

    ref.listen(fileProvider, (previous, next) {
       final index = ref.read(currentFileIndexProvider);
       if (index < next.length) {
         final newContent = next[index].content;
         if (_controller.text != newContent) {
            _controller.text = newContent;
         }
       }
    });

    return CodeTheme(
      data: CodeThemeData(styles: atomOneDarkTheme),
      child: CodeField(
        controller: _controller,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        expands: true,
        wrap: false,
        gutterStyle: const GutterStyle(
          width: 48,
          margin: 0,
          textStyle: TextStyle(color: Colors.grey),
        ),
        background: const Color(0xFF1E1E1E),
      ),
    );
  }
}
