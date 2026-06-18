import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../core/theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String? _activeFileId;
  String? _lastContent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
    });
  }

  void _initController() {
    final state = ref.read(fileProvider);
    if (state.activeFileId != null) {
      final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);
      _controller = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _lastContent = activeFile.content;
      _controller!.addListener(_onTextChanged);
      _activeFileId = state.activeFileId;
      if (mounted) setState(() {});
    }
  }

  void _onTextChanged() {
    if (_controller != null && _activeFileId != null) {
      if (_controller!.text != _lastContent) {
        _lastContent = _controller!.text;
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.watch(fileProvider);

    if (state.activeFileId != _activeFileId) {
      _activeFileId = state.activeFileId;
      if (_activeFileId != null) {
        final activeFile = state.files.firstWhere((f) => f.id == _activeFileId);
        _controller?.removeListener(_onTextChanged);
        _controller = CodeController(
          text: activeFile.content,
          language: dart,
        );
        _lastContent = activeFile.content;
        _controller!.addListener(_onTextChanged);
      } else {
        _controller?.removeListener(_onTextChanged);
        _controller = null;
        _lastContent = null;
      }
    } else if (_activeFileId != null && _controller != null) {
      final activeFile = state.files.firstWhere((f) => f.id == _activeFileId);
      if (activeFile.content != _controller!.text) {
          _controller!.removeListener(_onTextChanged);
          final oldSelection = _controller!.selection;
          _controller!.text = activeFile.content;
          _lastContent = activeFile.content;
          if (oldSelection.baseOffset <= _controller!.text.length) {
              _controller!.selection = oldSelection;
          } else {
              _controller!.selection = TextSelection.collapsed(offset: _controller!.text.length);
          }
          _controller!.addListener(_onTextChanged);
      }
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
    if (_controller == null) {
      return const Center(child: Text('No file opened', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace'),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: AppTheme.textSecondary),
            showLineNumbers: true,
          ),
        ),
      ),
    );
  }
}
