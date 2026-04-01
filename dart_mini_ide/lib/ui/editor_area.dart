import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../utils/colors.dart';

class EditorArea extends ConsumerStatefulWidget {
  const EditorArea({super.key});

  @override
  ConsumerState<EditorArea> createState() => _EditorAreaState();
}

class _EditorAreaState extends ConsumerState<EditorArea> {
  late CodeController _codeController;
  final FocusNode _focusNode = FocusNode();

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
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      if (_codeController.text != activeFile.content) {
         ref.read(fileProvider.notifier).updateFileContent(
          activeFile.id,
          _codeController.text,
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        final newActiveFile = next.activeFile;
        if (newActiveFile != null) {
          if (_codeController.text != newActiveFile.content) {
            _codeController.text = newActiveFile.content;
          }
        }
      } else {
         final currentActiveFile = next.activeFile;
         if (currentActiveFile != null && currentActiveFile.content != _codeController.text) {
             // In case content updated from another source (paste, download sync, etc)
             _codeController.text = currentActiveFile.content;
         }
      }
    });

    return Container(
      color: AppColors.editorBackground,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const SaveIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): const SaveIntent(),
        },
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                  ref.read(fileProvider.notifier).forceSaveCurrent(_codeController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File saved')),
                  );
               }
               return null;
            },
          ),
        },
        child: CodeTheme(
          data: CodeThemeData(styles: darculaTheme),
          child: SingleChildScrollView(
             child: CodeField(
              controller: _codeController,
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              gutterStyle: const GutterStyle(
                showLineNumbers: true,
                textStyle: TextStyle(color: AppColors.editorLineNumber),
                margin: 4.0,
              ),
              minLines: 10,
            ),
          )
        ),
      ),
    );
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}