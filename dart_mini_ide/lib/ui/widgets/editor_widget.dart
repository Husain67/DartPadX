import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../utils/constants.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _codeController;
  String _currentActiveId = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController!.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_codeController != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
    }
  }

  @override
  void dispose() {
    _codeController?.removeListener(_onCodeChanged);
    _codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId) {
        _currentActiveId = next.activeFileId;
        final activeFile = next.activeFile;
        if (activeFile != null) {
          // Temporarily remove listener to avoid triggering update back to state
          _codeController?.removeListener(_onCodeChanged);
          _codeController?.text = activeFile.content;
          _codeController?.addListener(_onCodeChanged);
        } else {
          _codeController?.removeListener(_onCodeChanged);
          _codeController?.text = '';
          _codeController?.addListener(_onCodeChanged);
        }
      } else {
        // If external change (like formatting) happens to same file
        final activeFile = next.activeFile;
        if (activeFile != null && _codeController!.text != activeFile.content) {
          _codeController?.removeListener(_onCodeChanged);
          _codeController?.text = activeFile.content;
          _codeController?.addListener(_onCodeChanged);
        }
      }
    });

    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && _currentActiveId.isEmpty) {
        _currentActiveId = activeFile.id;
        _codeController?.removeListener(_onCodeChanged);
        _codeController?.text = activeFile.content;
        _codeController?.addListener(_onCodeChanged);
    }

    return Container(
      color: AppColors.editorBg,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            ref.read(fileProvider.notifier).forceSaveActive();
          },
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
             ref.read(fileProvider.notifier).forceSaveActive();
          }
        },
        child: Focus(
          autofocus: true,
          child: CodeTheme(
            data: CodeThemeData(styles: darculaTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController!,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
