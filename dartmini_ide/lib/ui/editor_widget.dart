import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../core/theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _controller;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );

    _controller.addListener(() {
      if (_currentFileId != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      if (activeFile != null) {
        setState(() {
          _currentFileId = activeFile.id;
          _controller.text = activeFile.content;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the active file from other parts of the app
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentFileId && next.activeFileId != null) {
        final activeFile = ref.read(fileProvider.notifier).activeFile;
        if (activeFile != null) {
          setState(() {
            _currentFileId = activeFile.id;
            _controller.text = activeFile.content;
          });
        }
      }
    });

    final files = ref.watch(fileProvider.select((state) => state.files));
    final activeFileId = ref.watch(fileProvider.select((state) => state.activeFileId));

    if (files.isEmpty) {
      return const Center(
        child: Text(
          'No files open. Create or import a file.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Tabs
        Container(
          color: AppTheme.surfaceColor,
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final isActive = file.id == activeFileId;

              return GestureDetector(
                onTap: () {
                  ref.read(fileProvider.notifier).setActiveFile(file.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.backgroundStart : AppTheme.surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          ref.read(fileProvider.notifier).deleteFile(file.id);
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
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
              child: CodeField(
                controller: _controller,
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(color: Colors.grey),
                  width: 40,
                ),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
