import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CodeController _codeController;

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
    // Sync CodeController with Active File from Riverpod
    ref.listen(fileProvider, (previous, next) {
      final activeContent = next.activeFile?.content ?? '';
      if (_codeController.text != activeContent) {
        _codeController.text = activeContent;
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Deep dark
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Color(0xFFFACC15), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: Material(
              color: const Color(0xFFFACC15),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: execState.isRunning
                    ? null
                    : () {
                        final code = fileState.activeFile?.content ?? '';
                        ref.read(executionProvider.notifier).executeCode(code);
                      },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: execState.isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Row(
                          children: [
                            Icon(Icons.play_arrow, color: Colors.black, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Run',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toolbar
              const CustomToolbar(),

              // File Tabs
              Container(
                height: 40,
                color: const Color(0xFF151515),
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
                          color: isActive ? const Color(0xFF252525) : Colors.transparent,
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
                child: CodeTheme(
                  data: CodeThemeData(styles: monokaiSublimeTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _codeController,
                      gutterStyle: const GutterStyle(
                        showLineNumbers: true,
                        textStyle: TextStyle(color: Colors.white30, height: 1.5),
                      ),
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
                      background: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ),
              // Spacer for bottom sheet
              const SizedBox(height: 100),
            ],
          ),
          // Output Sheet
          const OutputSheet(),
        ],
      ),
    );
  }
}
