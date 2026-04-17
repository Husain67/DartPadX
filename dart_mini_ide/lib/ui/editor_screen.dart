import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late CodeController _codeController;
  Timer? _debounce;
  String _currentActiveId = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (_currentActiveId.isNotEmpty) {
        ref.read(fileProvider.notifier).updateContent(_codeController.text);
      }
    });
  }

  void _forceSave() {
    if (_currentActiveId.isNotEmpty) {
      ref.read(fileProvider.notifier).updateContent(_codeController.text);
    }
  }

  @override
  void dispose() {
    _forceSave();
    _codeController.removeListener(_onTextChanged);
    _codeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Synchronize controller with active file when changed
    ref.listen(fileProvider, (previous, next) {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      if (activeFile != null && activeFile.id != _currentActiveId) {
        _forceSave(); // Save old before switching
        _currentActiveId = activeFile.id;
        _codeController.text = activeFile.content;
      } else if (activeFile == null) {
        _currentActiveId = '';
        _codeController.text = '';
      }
    });

    final fileState = ref.watch(fileProvider);

    return Column(
      children: [
        // Tabs
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final f = fileState.files[index];
              final isActive = f.id == fileState.activeFileId;
              return GestureDetector(
                onTap: () {
                   ref.read(fileProvider.notifier).setActiveFile(f.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1a1a1a) : Colors.transparent,
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
                        f.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _forceSave();
                          ref.read(fileProvider.notifier).deleteFile(f.id);
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
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
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(showLineNumbers: true, textStyle: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
