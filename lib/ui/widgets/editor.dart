import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';

import '../../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _lastActiveFileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllerWithState();
    });
  }

  void _syncControllerWithState() {
    final state = ref.read(fileProvider);
    if (state.activeFileId == null) {
      if (_controller != null) {
        setState(() {
          _controller = null;
          _lastActiveFileId = null;
        });
      }
      return;
    }

    final activeFile = state.openFiles.firstWhere((f) => f.id == state.activeFileId);

    if (_lastActiveFileId != state.activeFileId) {
      // Switching files
      setState(() {
        _controller = CodeController(
          text: activeFile.content,
          language: dart,
        );
        _lastActiveFileId = activeFile.id;

        _controller!.addListener(_onTextChanged);
      });
    } else {
      // Same file, check if content changed externally
      if (_controller != null && _controller!.text != activeFile.content) {
         final currentSelection = _controller!.selection;

         // Remove listener to prevent circular updates
         _controller!.removeListener(_onTextChanged);
         _controller!.text = activeFile.content;

         // Try to restore selection safely
         if (currentSelection.baseOffset <= activeFile.content.length) {
            _controller!.selection = currentSelection;
         } else {
            _controller!.selection = TextSelection.collapsed(offset: activeFile.content.length);
         }

         _controller!.addListener(_onTextChanged);
      }
    }
  }

  void _onTextChanged() {
    if (_controller != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes to handle tab switches
    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        _syncControllerWithState();
      }
    });

    if (_controller == null) {
      return const Center(child: Text("No file opened", style: TextStyle(color: Colors.grey)));
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: darculaTheme['root']?.backgroundColor ?? const Color(0xFF2B2B2B),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller!,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              width: 48,
              margin: 8,
            ),
          ),
        ),
      ),
    );
  }
}
