import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';

import '../core/theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  Timer? _saveDebouncer;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    // Auto-save logic
    _codeController.addListener(() {
      if (_saveDebouncer?.isActive ?? false) _saveDebouncer!.cancel();
      _saveDebouncer = Timer(const Duration(seconds: 2), () {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
      });
    });
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _forceSave() {
    if (_saveDebouncer?.isActive ?? false) {
      _saveDebouncer!.cancel();
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for file changes to update the editor text
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        // Tab switched
        if (next.activeFile != null) {
           _codeController.text = next.activeFile!.content;
        }
      } else if (previous != null && next.activeFile != null) {
         // Same tab, maybe imported/formatted
         if (_codeController.text != next.activeFile!.content) {
            _codeController.text = next.activeFile!.content;
         }
      }
    });

    final fileState = ref.watch(fileProvider);
    final isExecuting = ref.watch(executionProvider).isExecuting;

    return Scaffold(
      extendBodyBehindAppBar: false,
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
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: isExecuting
                  ? null
                  : () {
                      FocusScope.of(context).unfocus(); // Dismiss keyboard
                      ref.read(executionProvider.notifier).runCode();
                    },
              icon: isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(
                isExecuting ? 'Running...' : 'Run',
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppTheme.accentYellow.withOpacity(0.5),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            // Tabs
            if (fileState.files.isNotEmpty)
              Container(
                height: 40,
                color: Colors.black26,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (context, index) {
                    final file = fileState.files[index];
                    final isActive = file.id == fileState.activeFileId;
                    return GestureDetector(
                      onTap: () {
                        if (!isActive) {
                          _forceSave();
                          ref.read(fileProvider.notifier).setActiveFile(file.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white10 : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? AppTheme.accentYellow : Colors.transparent,
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
                            if (fileState.files.length > 1) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  // Can't delete if it's the only tab
                                  ref.read(fileProvider.notifier).deleteFileById(file.id);
                                },
                                child: const Icon(Icons.close, size: 14, color: Colors.white54),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Toolbar
            const EditorToolbar(),

            // Editor
            Expanded(
              child: Stack(
                children: [
                  CodeTheme(
                    data: CodeThemeData(styles: atomOneDarkTheme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: _codeController,
                        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        gutterStyle: const GutterStyle(
                          showLineNumbers: true,
                          textStyle: TextStyle(color: Colors.white54),
                          width: 48,
                          margin: 8,
                        ),
                      ),
                    ),
                  ),

                  // Output Bottom Sheet Overlay
                  const OutputSheet(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
