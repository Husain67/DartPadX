import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';

class CodeEditorWidget extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onChanged;
  final CodeController controller;

  const CodeEditorWidget({
    super.key,
    required this.initialContent,
    required this.onChanged,
    required this.controller,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: draculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: widget.controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.grey),
            margin: 8.0,
          ),
          wrap: false,
        ),
      ),
    );
  }
}
