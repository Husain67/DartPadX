import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _currentFileId;

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
    if (_controller != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider.select((s) => s.files.firstWhere((f) => f.id == s.activeFileId, orElse: () => throw Exception('No active file'))));

    if (_controller == null || _currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      _initController(activeFile.content);
    } else if (_controller!.text != activeFile.content) {
      // Handle external updates (like paste)
      final currentSelection = _controller!.selection;
      _controller!.removeListener(_onTextChanged);
      _controller!.text = activeFile.content;

      if (currentSelection.baseOffset <= activeFile.content.length) {
         _controller!.selection = currentSelection;
      } else {
         _controller!.selection = TextSelection.collapsed(offset: activeFile.content.length);
      }

      _controller!.addListener(_onTextChanged);
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.white54, fontSize: 12),
            showLineNumbers: true,
          ),
        ),
      ),
    );
  }
}
