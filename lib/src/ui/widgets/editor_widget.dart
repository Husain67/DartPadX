import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _codeController;


  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(fileProvider);
      if (state.files.isNotEmpty && state.activeFileId.isNotEmpty) {
        final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);
        _codeController.removeListener(_onCodeChanged);
        _codeController.text = activeFile.content;
        _codeController.addListener(_onCodeChanged);
      }
    });
  }


  void _onCodeChanged() {
    // To prevent rebuilding the entire UI on every keystroke, we update the file content
    // in the provider without triggering a rebuild of the editor itself (if possible).
    // The FileNotifier has auto-save debounce handled internally.
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Listen to file changes to update the editor text without calling it during build phase
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.files.isNotEmpty && next.activeFileId.isNotEmpty) {
        final activeFile = next.files.firstWhere((f) => f.id == next.activeFileId);
        if (_codeController.text != activeFile.content) {
          _codeController.removeListener(_onCodeChanged);
          _codeController.text = activeFile.content;
          _codeController.addListener(_onCodeChanged);
        }
      }
    });

    final fileState = ref.watch(fileProvider);

    return Column(

      children: [
        // File Tabs
        Container(
          height: 40,
          color: Theme.of(context).scaffoldBackgroundColor,
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
                    color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                        width: 2,
                      ),
                      right: const BorderSide(color: Colors.white12, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white54,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (fileState.files.length > 1) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
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
        // Code Editor
        Expanded(
          child: fileState.files.isEmpty
              ? const Center(child: Text("No files open"))
              : CodeTheme(
                  data: CodeThemeData(styles: atomOneDarkTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _codeController,
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      background: const Color(0xFF1E1E1E),
                      minLines: 10,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
