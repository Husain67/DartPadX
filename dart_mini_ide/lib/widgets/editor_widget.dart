import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../models/code_file.dart';
import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  final CodeFile file;

  const EditorWidget({super.key, required this.file});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: widget.file.content,
      language: dart,
    );

    _codeController.addListener(() {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    });
  }

  @override
  void didUpdateWidget(covariant EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id != widget.file.id) {
      _codeController.text = widget.file.content;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _codeController,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(
              height: 1.5,
              fontSize: 14,
              color: Colors.white54,
            ),
            showLineNumbers: true,
            width: 40,
            margin: 10,
          ),
          background: Colors.transparent,
          expands: false,
          wrap: false,
        ),
      ),
    );
  }
}
