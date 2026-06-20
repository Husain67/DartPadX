import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _codeController;
  String _currentFileId = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllerWithState();
    });
  }

  void _onTextChanged() {
    final currentFile = ref.read(fileProvider.notifier).currentFile;
    if (currentFile != null && currentFile.content != _codeController.text) {
      ref.read(fileProvider.notifier).updateCurrentFileContent(_codeController.text);
    }
  }

  void _syncControllerWithState() {
    final currentFile = ref.read(fileProvider).currentFileId;
    final fileData = ref.read(fileProvider.notifier).currentFile;

    if (currentFile != _currentFileId) {
      _currentFileId = currentFile ?? '';
      if (fileData != null && fileData.content != _codeController.text) {
        _codeController.text = fileData.content;
      }
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onTextChanged);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (previous?.currentFileId != next.currentFileId) {
        _syncControllerWithState();
      }
    });

    final currentFile = ref.watch(fileProvider.select((state) => state.currentFileId));
    if (currentFile == null) {
      return const Center(child: Text('No file open'));
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: darculaTheme['root']?.backgroundColor ?? const Color(0xFF2B2B2B),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _codeController,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(color: Colors.white54, height: 1.5),
              showLineNumbers: true,
              showErrors: true,
              showFoldingHandles: true,
            ),
          ),
        ),
      ),
    );
  }
}
