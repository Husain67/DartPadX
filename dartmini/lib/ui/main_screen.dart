import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';

import '../theme.dart';
import '../providers/file_notifier.dart';
import '../providers/execution_notifier.dart';
import 'toolbar.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  String _currentActiveId = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncEditorState();
    });
  }

  void _onCodeChanged() {
    final activeId = ref.read(fileProvider).activeFileId;
    if (activeId != null && activeId == _currentActiveId) {
      ref.read(fileProvider.notifier).updateContent(_codeController.text);
    }
  }

  void _syncEditorState() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      _currentActiveId = activeFile.id;
      if (_codeController.text != activeFile.content) {
        _codeController.text = activeFile.content;
      }
    } else {
      _currentActiveId = '';
      _codeController.text = '';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        _syncEditorState();
      }
    });

    final files = ref.watch(fileProvider.select((state) => state.files));
    final activeId = ref.watch(fileProvider.select((state) => state.activeFileId));
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: executionState.isRunning
                  ? null
                  : () {
                      final stdin = ref.read(stdinProvider);
                      ref.read(executionProvider.notifier).executeCode(_codeController.text, stdin);
                      _showOutputSheet(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: executionState.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow, size: 20),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Column(
          children: [
            const ToolbarWidget(),
            // File Tabs
            SizedBox(
              height: 40,
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
                        color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
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
                              color: isActive ? Colors.white : Colors.white54,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ref.read(fileProvider.notifier).setActiveFile(file.id);
                              ref.read(fileProvider.notifier).deleteActiveFile();
                            },
                            child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.white54),
                          )
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
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: const GutterStyle(
                      textStyle: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                      showLineNumbers: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const OutputSheet(),
    );
  }
}

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (!execState.isRunning && execState.executionTime.isNotEmpty)
                      Text(
                        'Time: ${execState.executionTime} | Mem: ${execState.memory}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              // Stdin input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Enter STDIN here (optional)...',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryAccent)),
                    isDense: true,
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
                    if (execState.stdout.isNotEmpty)
                      Text(execState.stdout, style: const TextStyle(color: Colors.lightGreenAccent, fontFamily: 'monospace')),
                    if (execState.stderr.isNotEmpty) ...[
                      if (execState.stdout.isNotEmpty) const SizedBox(height: 16),
                      Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                    ],
                    if (!execState.isRunning && execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text('No output.', style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
