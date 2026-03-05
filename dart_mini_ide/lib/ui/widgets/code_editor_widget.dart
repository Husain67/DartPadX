import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import '../../core/constants.dart';
import '../../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController controller;

  @override
  void initState() {
    super.initState();
    final fileState = ref.read(fileProvider);
    final currentCode = fileState.currentFile?.content ?? '';

    controller = CodeController(
      text: currentCode,
      language: dart,
    );

    controller.addListener(() {
      ref.read(fileProvider.notifier).updateCurrentFileContent(controller.text);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.currentFileId != next.currentFileId) {
        final newCode = next.currentFile?.content ?? '';
        if (controller.text != newCode) {
          controller.text = newCode;
        }
      }
    });

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            showLineNumbers: true,
            textStyle: TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', fontSize: 14),
            margin: 4.0,
            width: 40.0,
          ),
        ),
      ),
    );
  }
}
