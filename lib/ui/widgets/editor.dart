import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String _currentFileId = '';
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
    ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider).activeFile;

    if (activeFile == null) {
      return const Center(child: Text("No active file"));
    }

    // Re-init controller if file changes
    if (_currentFileId != activeFile.id || _controller == null) {
      _currentFileId = activeFile.id;
      _initController(activeFile.content);
    } else if (_controller!.text != activeFile.content) {
      // Sync content from external changes (e.g. paste, format)
      _isUpdating = true;
      final cursor = _controller!.selection;
      _controller!.text = activeFile.content;
      _controller!.selection = cursor.copyWith(
        baseOffset: cursor.baseOffset.clamp(0, activeFile.content.length),
        extentOffset: cursor.extentOffset.clamp(0, activeFile.content.length),
      );
      _isUpdating = false;
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.white54, fontSize: 14),
            showLineNumbers: true,
          ),
          wrap: false,
        ),
      ),
    );
  }
}
