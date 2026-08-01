import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String _activeFileId = '';
  bool _isUpdatingFromProvider = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String initialText) {
    _controller?.dispose();
    _controller = CodeController(
      text: initialText,
      language: dart,
    );
    _controller!.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_isUpdatingFromProvider) return;

    final text = _controller!.text;
    ref.read(fileProvider.notifier).updateActiveFileContent(text);
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text('No file opened'));
    }

    if (_controller == null || _activeFileId != activeFile.id) {
      _activeFileId = activeFile.id;
      _initController(activeFile.content);
    } else {
      // Sync from outside changes (like format, paste, etc)
      if (_controller!.text != activeFile.content) {
         _isUpdatingFromProvider = true;
         _controller!.text = activeFile.content;
         _isUpdatingFromProvider = false;
      }
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            showLineNumbers: true,
            margin: 8.0,
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
