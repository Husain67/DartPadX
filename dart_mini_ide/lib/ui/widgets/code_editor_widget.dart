import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/dracula.dart';

import '../../logic/providers/files_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  Timer? _autoSaveTimer;
  String? _lastId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );

    // Auto-save timer (every 2 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      ref.read(filesProvider.notifier).saveActiveFile();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(filesProvider);
    final activeFile = filesState.activeFile;

    // Listen to changes in the active file from the provider
    ref.listen(filesProvider, (previous, next) {
      final nextFile = next.activeFile;
      if (nextFile != null) {
        bool fileSwitched = previous?.activeFile?.id != nextFile.id;
        bool contentChangedExternally = previous?.activeFile?.content != nextFile.content &&
                                        _controller.text != nextFile.content;

        if (fileSwitched || contentChangedExternally) {
           // Update controller only if needed to avoid cursor jump loop or conflicts
           // If we are typing, onChanged updates state, so content matches controller.
           // If external action (Format, Paste button) updates state, content differs from controller.
           if (_controller.text != nextFile.content) {
             // Preserve cursor position if possible, but difficult on full replace.
             // For simplicity, just update text.
             _controller.text = nextFile.content;
           }
        }
      }
    });

    if (activeFile == null) {
      return const Center(child: Text('No file selected', style: TextStyle(color: Colors.grey)));
    }

    // Initial sync on first build if controller is empty (or on hard refresh)
    if (_lastId != activeFile.id) {
       _controller.text = activeFile.content;
       _lastId = activeFile.id;
    }

    return CodeTheme(
      data: CodeThemeData(styles: draculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            width: 50,
            margin: 5,
          ),
          onChanged: (value) {
            // Update the state in memory
            ref.read(filesProvider.notifier).updateActiveFileContent(value);
          },
        ),
      ),
    );
  }
}
