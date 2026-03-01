import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'dart:async';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter/services.dart';
import 'package:highlight/languages/dart.dart';
import 'package:dart_style/dart_style.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/preset_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _currentFileId;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _formatCode() {
    if (_controller != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
      try {
        final formatter = DartFormatter();
        final formattedCode = formatter.format(_controller!.text);
        final selection = _controller!.selection;
        _controller!.text = formattedCode;
        if (selection.start <= formattedCode.length && selection.end <= formattedCode.length) {
          _controller!.selection = selection;
        }
      } catch (e) {
        // Format err
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    if (fileState.activeFile == null) {
      return const Center(child: Text('No file open', style: TextStyle(color: Colors.grey)));
    }

    if (_currentFileId != fileState.activeFileId) {
      _currentFileId = fileState.activeFileId;
      _controller?.dispose();
      _controller = CodeController(
        text: fileState.activeFile!.content,
        language: dart,
      );

      _controller!.addListener(() {
        final currentFile = ref.read(fileProvider).activeFile;
        if (currentFile != null && _controller!.text != currentFile.content) {
          if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
          _debounceTimer = Timer(const Duration(seconds: 2), () {
            ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
          });
        }
      });
    } else if (_controller?.text != fileState.activeFile!.content) {
      final text = fileState.activeFile!.content;
      final selection = _controller!.selection;
      _controller!.text = text;
      if (selection.start <= text.length && selection.end <= text.length) {
        _controller!.selection = selection;
      }
    }

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): _formatCode,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): _formatCode,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): () {
          final fileState = ref.read(fileProvider);
          if (fileState.activeFile != null) {
             ref.read(executionProvider.notifier).executeCode(
               fileState.activeFile!.content,
               ref.read(presetProvider).activePreset
             );
          }
        },
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR): () {
          final fileState = ref.read(fileProvider);
          if (fileState.activeFile != null) {
             ref.read(executionProvider.notifier).executeCode(
               fileState.activeFile!.content,
               ref.read(presetProvider).activePreset
             );
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller!,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFFFACC15).withOpacity(0.8),
                onPressed: _formatCode,
                tooltip: 'Format & Save (Ctrl+S)',
                child: const Icon(Icons.format_align_left, color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}
