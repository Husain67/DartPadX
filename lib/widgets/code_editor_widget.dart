import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/providers.dart';

// Key for accessing controller externally
final editorKey = GlobalKey<_CodeEditorWidgetState>();

class CodeEditorWidget extends ConsumerStatefulWidget {
  CodeEditorWidget({Key? key}) : super(key: key ?? editorKey);

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _lastActiveId;
  bool _updatingProgrammatically = false;

  CodeController? get controller => _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _controller!.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_controller != null && !_updatingProgrammatically) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first,
    );

    if (_lastActiveId != activeFile.id) {
      _lastActiveId = activeFile.id;
      _initController(activeFile.content);
    } else if (_controller != null && _controller!.text != activeFile.content) {
      // Sync programmatic updates (like format or paste) from state back to controller
      _updatingProgrammatically = true;
      final oldSelection = _controller!.selection;
      _controller!.text = activeFile.content;
      if (oldSelection.baseOffset <= activeFile.content.length) {
         _controller!.selection = oldSelection;
      } else {
         _controller!.selection = TextSelection.collapsed(offset: activeFile.content.length);
      }
      _updatingProgrammatically = false;
    }

    return Column(
      children: [
        // File Tabs
        Container(
          height: 40,
          color: const Color(0xFF121212),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == fileState.activeFileId;

              return GestureDetector(
                onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF252525) : Colors.transparent,
                    border: isActive
                      ? const Border(top: BorderSide(color: Color(0xFFFACC15), width: 2))
                      : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isActive ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Editor
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: darculaTheme),
            child: SingleChildScrollView(
              child: _controller != null
                ? CodeField(
                    controller: _controller!,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: const GutterStyle(
                      textStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}
