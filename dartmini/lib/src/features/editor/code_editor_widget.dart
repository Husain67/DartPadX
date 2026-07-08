import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/editor_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _currentFileId;
  bool _isUpdatingFromProvider = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String text, String fileId) {
    _controller?.dispose();
    _controller = CodeController(
      text: text,
      language: dart,
    );
    _currentFileId = fileId;

    _controller!.addListener(() {
      if (!_isUpdatingFromProvider && _controller != null) {
        ref.read(editorProvider.notifier).updateActiveFileContent(_controller!.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final activeFile = editorState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text('No file open'));
    }

    if (_currentFileId != activeFile.id) {
      _isUpdatingFromProvider = true;
      _initController(activeFile.content, activeFile.id);
      _isUpdatingFromProvider = false;
    } else if (_controller != null && _controller!.text != activeFile.content) {
      // Content updated from elsewhere (e.g. paste from toolbar)
      _isUpdatingFromProvider = true;
      final selection = _controller!.selection;
      _controller!.text = activeFile.content;
      if (selection.baseOffset <= activeFile.content.length) {
        _controller!.selection = selection;
      } else {
        _controller!.selection = TextSelection.collapsed(offset: activeFile.content.length);
      }
      _isUpdatingFromProvider = false;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          // Auto-saving is handled by provider, just provide a visual cue if needed
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File saved'), duration: Duration(seconds: 1)));
        },
      },
      child: Column(
        children: [
          _buildTabBar(editorState),
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: darculaTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller!,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  gutterStyle: const GutterStyle(
                    textStyle: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'monospace'),
                    width: 48,
                    margin: 8,
                  ),
                  expands: false,
                  wrap: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(EditorState state) {
    return Container(
      height: 40,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = file.id == state.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(editorProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF050505) : const Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(editorProvider.notifier).deleteFile(file.id),
                    child: Icon(Icons.close, size: 16, color: isActive ? Colors.white : Colors.white54),
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
