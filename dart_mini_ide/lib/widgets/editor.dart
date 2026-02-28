import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/dart.dart';
import 'dart:async';

import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _controller;
  Timer? _saveTimer;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: dart,
      text: '',
    );
    _controller.addListener(_onTextChanged);

    // Auto-save timer
    _saveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      ref.read(fileProvider.notifier).saveActiveFile();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_currentFileId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    // Handle file switching or external content updates
    if (activeFile != null) {
      if (_currentFileId != activeFile.id || fileState.isContentChangedExternally) {
        _currentFileId = activeFile.id;

        // Preserve cursor position if possible or just update text
        final text = activeFile.content;
        if (_controller.text != text) {
           _controller.text = text;
        }

        // Reset external flag after handling
        if (fileState.isContentChangedExternally) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             ref.read(fileProvider.notifier).setActiveFile(activeFile.id);
             // Directly updating state from widget is not allowed, we trigger update via provider method
             ref.read(fileProvider.notifier).updateActiveFileContent(activeFile.content, isExternal: false);
          });
        }
      }
    } else {
       if (_controller.text.isNotEmpty) {
          _controller.text = '';
       }
    }

    return CodeTheme(
      data: CodeThemeData(styles: vs2015Theme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
             showLineNumbers: true,
             margin: 8.0,
             textStyle: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          wrap: true,
        ),
      ),
    );
  }
}
