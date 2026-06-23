import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';

class CodeEditorWidget extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onChanged;

  const CodeEditorWidget({
    super.key,
    required this.initialContent,
    required this.onChanged,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: widget.initialContent,
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    widget.onChanged(_codeController.text);
  }

  @override
  void didUpdateWidget(covariant CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != _codeController.text) {
      final selection = _codeController.selection;
      _codeController.removeListener(_onCodeChanged);
      _codeController.text = widget.initialContent;

      // Attempt to preserve cursor position, but bound it safely
      final newLength = widget.initialContent.length;
      final newBaseOffset = selection.baseOffset.clamp(0, newLength);
      final newExtentOffset = selection.extentOffset.clamp(0, newLength);

      _codeController.selection = TextSelection(
        baseOffset: newBaseOffset,
        extentOffset: newExtentOffset,
      );

      _codeController.addListener(_onCodeChanged);
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
    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _codeController,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
            ),
          ),
          background: Colors.transparent,
        ),
      ),
    );
  }
}
