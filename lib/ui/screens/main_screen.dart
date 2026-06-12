import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';

import '../../providers/file_notifier.dart';
import '../../providers/execution_notifier.dart';
import '../../providers/compiler_notifier.dart';
import '../../theme/app_theme.dart';
import '../widgets/editor_tabs.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final TextEditingController _stdinController = TextEditingController();
  String? _lastActiveFileId;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      language: dart,
      text: '',
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.content != _codeController.text) {
      ref.read(fileProvider.notifier).updateFileContent(activeFile.id, _codeController.text);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);
    final activeFile = fileState.activeFile;

    // Sync controller when active file changes
    if (activeFile != null && activeFile.id != _lastActiveFileId) {
      _lastActiveFileId = activeFile.id;
      // Use post frame to avoid build phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_codeController.text != activeFile.content) {
          _codeController.text = activeFile.content;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run'),
              onPressed: execState.isRunning ? null : () {
                final preset = ref.read(compilerProvider).activePreset;
                if (preset != null && activeFile != null) {
                  ref.read(executionProvider.notifier).executeCode(
                    code: activeFile.content,
                    stdinStr: _stdinController.text,
                    preset: preset,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: Column(
            children: [
              const EditorToolbar(),
              const EditorTabs(),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: CodeTheme(
                              data: CodeThemeData(styles: darculaTheme),
                              child: CodeField(
                                controller: _codeController,
                                gutterStyle: const GutterStyle(
                                  textStyle: TextStyle(height: 1.5, color: Colors.grey),
                                  margin: 8.0,
                                ),
                                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        // Stdin input field at the bottom of editor
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          color: AppTheme.surfaceColor,
                          child: TextField(
                            controller: _stdinController,
                            decoration: const InputDecoration(
                              hintText: 'Standard Input (stdin)',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              isDense: true,
                            ),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(height: 40), // space for bottom sheet handle
                      ],
                    ),
                    const OutputSheet(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
