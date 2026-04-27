import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/providers.dart';

class CodeEditorArea extends ConsumerStatefulWidget {
  const CodeEditorArea({super.key});

  @override
  ConsumerState<CodeEditorArea> createState() => _CodeEditorAreaState();
}

class _CodeEditorAreaState extends ConsumerState<CodeEditorArea> {
  CodeController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: dart,
      text: ref.read(fileProvider).activeFile?.content ?? '',
    );
    _controller!.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (_controller != null && next.activeFile != null) {
        if (_controller!.text != next.activeFile!.content) {
          final oldSelection = _controller!.selection;
          _controller!.removeListener(_onTextChanged);
          _controller!.text = next.activeFile!.content;
          _controller!.selection = oldSelection;
          _controller!.addListener(_onTextChanged);
        }
      }
    });

    if (_controller == null) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color(0xFF1a1a1a),
      child: CodeTheme(
        data: CodeThemeData(styles: draculaTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller!,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              showLineNumbers: true,
              margin: 4.0,
              textStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
