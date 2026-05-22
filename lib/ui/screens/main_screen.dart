import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';

import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../services/execution_service.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  Timer? _autoSaveTimer;
  String _currentFileId = '';

  final TextEditingController _stdinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEditor();
    });
  }

  void _initEditor() {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      _currentFileId = activeFile.id;
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _codeController!.addListener(_onTextChanged);
      setState(() {});
    }
  }

  void _onTextChanged() {
    if (_codeController == null) return;
    final text = _codeController!.text;

    // Auto-save logic
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(editorProvider.notifier).updateContent(_currentFileId, text);
      }
    });
  }

  void _syncEditorWithState() {
     final activeFile = ref.read(editorProvider).activeFile;
     if (activeFile == null) return;

     if (activeFile.id != _currentFileId) {
        // Switched file
        _currentFileId = activeFile.id;
        _codeController?.removeListener(_onTextChanged);
        _codeController = CodeController(
          text: activeFile.content,
          language: dart,
        );
        _codeController!.addListener(_onTextChanged);
     } else if (_codeController!.text != activeFile.content) {
        // Content updated externally (e.g., paste from toolbar)
        final oldSelection = _codeController!.selection;
        _codeController!.text = activeFile.content;

        if (oldSelection.baseOffset <= activeFile.content.length) {
            _codeController!.selection = oldSelection;
        } else {
             _codeController!.selection = TextSelection.collapsed(offset: activeFile.content.length);
        }
     }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _codeController?.removeListener(_onTextChanged);
    _codeController?.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile == null) return;

    // Force save before run
    _autoSaveTimer?.cancel();
    ref.read(editorProvider.notifier).updateContent(_currentFileId, _codeController!.text);

    ref.read(executionProvider.notifier).setExecuting(true);

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.presets.cast<dynamic>().firstWhere(
        (p) => p.id == compilerState.activePresetId,
        orElse: () => null
    );

    final result = await ExecutionService.executeCode(
      code: _codeController!.text,
      stdin: ref.read(stdinProvider),
      useDefault: compilerState.useDefaultCompiler,
      preset: preset,
    );

    if (mounted) {
      ref.read(executionProvider.notifier).setResult(
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        error: result['error'] ?? '',
        time: result['time'] ?? '',
        memory: result['memory'] ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to editor state changes to update UI and controller
    ref.listen(editorProvider, (previous, next) {
        _syncEditorWithState();
        setState(() {}); // Trigger rebuild for tabs
    });

    final editorState = ref.watch(editorProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: execState.isExecuting ? null : _runCode,
              icon: execState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
              label: const Text('Run'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toolbar
              EditorToolbar(
                onCodeImported: (code) {
                   if (_codeController != null) {
                       final cursor = _codeController!.selection.baseOffset;
                       if (cursor >= 0) {
                           final current = _codeController!.text;
                           final updated = current.substring(0, cursor) + code + current.substring(cursor);
                           _codeController!.text = updated;
                       } else {
                           _codeController!.text += code;
                       }
                       // Force state update to sync cursor
                       ref.read(editorProvider.notifier).updateContent(_currentFileId, _codeController!.text);
                       ref.read(editorProvider.notifier).updateContent(_currentFileId, _codeController!.text); // handled inside updateContent instead of mutating state directly
                   }
                },
              ),

              // File Tabs
              if (editorState.files.isNotEmpty)
                Container(
                  height: 40,
                  color: const Color(0xFF121212),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: editorState.files.length,
                    itemBuilder: (context, index) {
                      final file = editorState.files[index];
                      final isActive = file.id == editorState.activeFileId;
                      return GestureDetector(
                        onTap: () => ref.read(editorProvider.notifier).setActiveFile(file.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2D2D2D) : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isActive ? AppTheme.primaryAccent : Colors.transparent,
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
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => ref.read(editorProvider.notifier).deleteFile(file.id),
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // STDIN Input
              Container(
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _stdinController,
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)...',
                    hintStyle: TextStyle(color: Colors.grey),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              // Code Editor
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF282C34), // One Dark bg
                  child: _codeController == null
                      ? const Center(child: CircularProgressIndicator())
                      : CodeTheme(
                          data: CodeThemeData(styles: atomOneDarkTheme),
                          child: SingleChildScrollView(
                            child: CodeField(
                              controller: _codeController!,
                              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              gutterStyle: const GutterStyle(
                                showLineNumbers: true,
                                showErrors: false,
                                showFoldingHandles: false,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Output Sheet Layer
          const OutputSheet(),
        ],
      ),
    );
  }
}
