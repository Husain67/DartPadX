import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({super.key});

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  late CodeController _codeController;
  String _currentFileId = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentFileId.isNotEmpty) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentFileId) {
        _currentFileId = next.activeFileId;
        final activeFile = ref.read(fileProvider.notifier).activeFile;
        if (activeFile != null && _codeController.text != activeFile.content) {
          _codeController.text = activeFile.content;
        }
      }
    });

    // Initial load
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && _currentFileId.isEmpty) {
      _currentFileId = activeFile.id;
      _codeController.text = activeFile.content;
    }

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _codeController,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          lineNumberStyle: const LineNumberStyle(
            textStyle: TextStyle(color: Colors.grey),
            margin: 16,
          ),
          background: Colors.transparent,
          expands: false,
        ),
      ),
    );
  }
}
