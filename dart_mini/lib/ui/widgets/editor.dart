import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../core/theme.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      language: dart,
      text: '',
    );

    _codeController.addListener(() {
      if (!mounted) return;
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != previous?.activeFileId || next.files.length != previous?.files.length) {
         if (next.activeFile != null && _codeController.text != next.activeFile!.content) {
            _codeController.text = next.activeFile!.content;
         }
      }
    });

    if (activeFile == null) {
      return const Center(
        child: Text('No file selected', style: TextStyle(color: Colors.white54)),
      );
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: AppTheme.backgroundColor1,
        child: SingleChildScrollView(
          child: CodeField(
            controller: _codeController,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(color: Colors.white54, height: 1.5),
              showLineNumbers: true,
              margin: 8.0,
            ),
          ),
        ),
      ),
    );
  }
}
