import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _codeController;
  Timer? _debounceTimer;
  String _currentActiveId = '';

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
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    });
  }

  void _forceSave() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId) {
        _forceSave(); // Save old file before switching
        _currentActiveId = next.activeFileId;
        final active = next.activeFile;
        if (active != null && _codeController.text != active.content) {
          _codeController.text = active.content;
        }
      } else {
        // Same file, maybe content updated externally (e.g. Paste)
        final active = next.activeFile;
        if (active != null && _codeController.text != active.content) {
          // If updated from outside (like format or paste), sync it
          _codeController.text = active.content;
        }
      }
    });

    // Initialize controller on first build if needed
    if (_currentActiveId.isEmpty && fileState.activeFileId.isNotEmpty) {
      _currentActiveId = fileState.activeFileId;
      final active = fileState.activeFile;
      if (active != null) {
        _codeController.text = active.content;
      }
    }

    return Column(
      children: [
        _buildTabs(fileState),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                gutterStyle: const GutterStyle(showLineNumbers: true),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(FileState state) {
    return Container(
      height: 40,
      color: Colors.black,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (ctx, index) {
          final file = state.files[index];
          final isActive = file.id == state.activeFileId;
          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1a1a1a) : Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(fileProvider.notifier).deleteFileById(file.id);
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
