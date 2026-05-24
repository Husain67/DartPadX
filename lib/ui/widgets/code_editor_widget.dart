import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
    _controller.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentFileId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider).activeFile;

    if (activeFile != null) {
      _currentFileId = activeFile.id;
      if (_controller.text != activeFile.content) {
        _controller.text = activeFile.content;
      }
    }

    return Container(
      color: DartMiniTheme.background,
      child: CodeTheme(
        data: CodeThemeData(styles: monokaiSublimeTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(color: Colors.white54, height: 1.5),
              width: 48,
              margin: 8,
            ),
          ),
        ),
      ),
    );
  }
}
