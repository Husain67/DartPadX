import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../data/providers/files_provider.dart';
import '../../core/theme/app_theme.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  String _currentFileId = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );

    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProvider();
    });
  }

  void _onTextChanged() {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile != null && activeFile.content != _controller.text) {
      ref.read(filesProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  void _syncWithProvider() {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile != null && _currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      _controller.text = activeFile.content;
    } else if (activeFile != null && _controller.text != activeFile.content) {
      // Force update if needed without losing cursor (useful for paste/format)
      final selection = _controller.selection;
      _controller.text = activeFile.content;
      if (selection.baseOffset <= _controller.text.length) {
        _controller.selection = selection;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filesProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId ||
          (next.activeFile != null && next.activeFile!.content != _controller.text && _currentFileId == next.activeFileId)) {
        _syncWithProvider();
      }
    });

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            showLineNumbers: true,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }
}
