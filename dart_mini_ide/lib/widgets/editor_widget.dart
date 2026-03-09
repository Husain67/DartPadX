import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';
import 'package:dart_style/dart_style.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  Timer? _debounceTimer;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    // Hardware keyboard shortcuts
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    _controller?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                     HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                     HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                     HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);

      if (isCtrl) {
        if (event.logicalKey == LogicalKeyboardKey.keyS) {
          _formatCode();
          _saveCurrent();
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
          _runCode();
          return true;
        }
      }
    }
    return false;
  }

  void _runCode() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
       ref.read(executionProvider.notifier).executeCode(activeFile.content);
    }
  }

  void _formatCode() {
    if (_controller == null) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(_controller!.text);
      if (formatted != _controller!.text) {
        _controller!.text = formatted;
        _saveCurrent();
      }
    } catch (e) {
      // Ignore formatting errors during partial typing
    }
  }

  void _saveCurrent() {
    if (_currentFileId != null && _controller != null) {
      ref.read(fileProvider.notifier).updateFileContent(_currentFileId!, _controller!.text);
    }
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _saveCurrent();
    });
  }

  void _initControllerIfNeeded(String text) {
    if (_controller == null) {
      _controller = CodeController(
        text: text,
        language: dart,
      );
      _controller!.addListener(_onTextChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider.select((s) => ref.read(fileProvider.notifier).activeFile));

    if (activeFile == null) {
      return const Center(
        child: Text(
          'No file selected',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    if (_currentFileId != activeFile.id) {
      // Force save previous before switching
      _saveCurrent();

      _currentFileId = activeFile.id;
      if (_controller != null) {
        _controller!.removeListener(_onTextChanged);
        _controller!.dispose();
        _controller = null;
      }
      _initControllerIfNeeded(activeFile.content);
    } else if (_controller != null && _controller!.text != activeFile.content) {
      // External update (like import or paste)
      final selection = _controller!.selection;
      _controller!.text = activeFile.content;

      // Attempt to restore cursor safely
      if (selection.baseOffset <= _controller!.text.length) {
         _controller!.selection = selection;
      }
    }

    return CodeTheme(
      data: CodeThemeData(styles: atomOneDarkTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            showLineNumbers: true,
            textStyle: TextStyle(color: Colors.white38, fontSize: 12),
            margin: 8.0,
          ),
          wrap: true,
        ),
      ),
    );
  }
}
