import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  Timer? _debounce;
  String? _currentFileId;

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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (_currentFileId != null && _currentFileId == ref.read(fileProvider).activeFileId) {
        ref.read(fileProvider.notifier).updateActiveContent(_codeController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _runCode() {
    // Force save before running
    ref.read(fileProvider.notifier).updateActiveContent(_codeController.text);
    ref.read(executionProvider.notifier).executeCode(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentFileId) {
        // Save previous file if changing tabs
        if (_currentFileId != null && previous != null) {
          final previousFile = previous.files.where((f) => f.id == _currentFileId).firstOrNull;
          if (previousFile != null) {
            // we have unsaved changes in the controller that need to go to hive before we swap
            // But state management via notifier does this, we just ensure _updateActiveContent handles it
            ref.read(fileProvider.notifier).updateActiveContent(_codeController.text);
          }
        }

        _currentFileId = next.activeFileId;
        final newFile = next.activeFile;
        if (newFile != null && _codeController.text != newFile.content) {
          _codeController.text = newFile.content;
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
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
              onPressed: execState.isRunning ? null : _runCode,
              icon: execState.isRunning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run'),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 56, child: ToolbarWidget()), // 56px exactly
            // File Tabs
            if (fileState.files.isNotEmpty)
              SizedBox(
                height: 40,
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
                          color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                          border: Border(bottom: BorderSide(color: isActive ? AppTheme.accentYellow : Colors.transparent, width: 2)),
                        ),
                        child: Row(
                          children: [
                            Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                ref.read(fileProvider.notifier).deleteFile(file.id);
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
                    gutterStyle: const GutterStyle(showLineNumbers: true, showErrors: false, showFoldingHandles: false),
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: const OutputSheetWidget(),
    );
  }
}
