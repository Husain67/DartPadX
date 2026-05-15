import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'dart:async';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../core/theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  final TextEditingController _stdinController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController!.addListener(_onCodeChanged);
    _stdinController.addListener(_onStdinChanged);
  }

  void _onCodeChanged() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && activeFile.content != _codeController!.text) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
      });
    }
  }

  void _onStdinChanged() {
    ref.read(stdinProvider.notifier).state = _stdinController.text;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _codeController?.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
         final active = next.files.firstWhere((f) => f.id == next.activeFileId);
         if (_codeController!.text != active.content) {
             _codeController!.text = active.content;
         }
      }
    }, fireImmediately: true);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: execState.isRunning
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      ref.read(executionProvider.notifier).executeCode();
                    },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const ToolbarWidget(),
              // File Tabs
              Container(
                height: 40,
                color: AppTheme.backgroundStart,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (context, index) {
                    final f = fileState.files[index];
                    final isActive = f.id == fileState.activeFileId;
                    return InkWell(
                      onTap: () {
                        ref.read(fileProvider.notifier).setActiveFile(f.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.backgroundEnd : AppTheme.backgroundStart,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(f.name, style: TextStyle(color: isActive ? AppTheme.pureWhite : Colors.white54)),
                            const SizedBox(width: 8),
                            if (fileState.files.length > 1)
                              InkWell(
                                onTap: () {
                                  if (isActive) {
                                    ref.read(fileProvider.notifier).deleteActiveFile();
                                  }
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.white54),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Editor and Stdin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: AppTheme.backgroundEnd,
                        child: CodeTheme(
                          data: CodeThemeData(styles: atomOneDarkTheme),
                          child: SingleChildScrollView(
                            child: CodeField(
                              controller: _codeController!,
                              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              lineNumberStyle: const LineNumberStyle(
                                width: 48,
                                textStyle: TextStyle(color: Colors.white38),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: AppTheme.backgroundStart,
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Standard Input (stdin)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TextField(
                                controller: _stdinController,
                                maxLines: null,
                                expands: true,
                                decoration: const InputDecoration(
                                  hintText: 'Enter input data here...',
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }
}
