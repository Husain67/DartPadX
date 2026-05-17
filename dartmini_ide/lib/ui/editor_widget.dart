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
  late CodeController _controller;
  String? _currentActiveId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithState();
    });
  }

  void _onTextChanged() {
    // Only update if it's the active file and text actually changed
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active != null && active.content != _controller.text) {
       ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  void _syncWithState() {
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active != null) {
      _currentActiveId = active.id;
      if (_controller.text != active.content) {
         _controller.text = active.content;
      }
    } else {
      _currentActiveId = null;
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        // Switched file, force save previous
        if (_currentActiveId != null && previous != null) {
             ref.read(fileProvider.notifier).forceSaveActiveFile();
        }
        _syncWithState();
      } else if (ref.read(fileProvider.notifier).activeFile?.content != _controller.text) {
          // Triggered by paste/format
          _syncWithState();
      }
    });

    final files = ref.watch(fileProvider.select((s) => s.files));
    final activeId = ref.watch(fileProvider.select((s) => s.activeFileId));

    return Column(
      children: [
        // File Tabs
        Container(
          height: 40,
          color: const Color(0xFF121212),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final isActive = file.id == activeId;
              return GestureDetector(
                onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
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
                          color: isActive ? Colors.white : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            ref.read(fileProvider.notifier).deleteFile(file.id);
                          },
                          child: const Icon(Icons.close, size: 14, color: Colors.white54),
                        ),
                      ]
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
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                background: const Color(0xFF1E1E1E),
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(color: Colors.white38),
                  background: Color(0xFF121212),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
