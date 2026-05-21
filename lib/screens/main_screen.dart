import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_tabs.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final TextEditingController _stdinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    _codeController.addListener(() {
      if (mounted) {
         ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncEditor();
    });
  }

  void _syncEditor() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && _codeController.text != activeFile.content) {
      _codeController.text = activeFile.content;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to file changes to update editor text if switched
    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        final newActiveFile = next.files.firstWhere((f) => f.id == next.activeFileId, orElse: () => next.files.first);
        if (_codeController.text != newActiveFile.content) {
          _codeController.text = newActiveFile.content;
        }
      } else if (previous != null) {
          // Check if active file content was changed externally (e.g., paste, format)
          final prevActive = previous.files.firstWhere((f) => f.id == previous.activeFileId, orElse: () => previous.files.first);
          final nextActive = next.files.firstWhere((f) => f.id == next.activeFileId, orElse: () => next.files.first);

          if (prevActive.content != nextActive.content && _codeController.text != nextActive.content) {
             _codeController.text = nextActive.content;
          }
      }
    });

    final isRunning = ref.watch(executionProvider).isRunning;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(isRunning),
                  ToolbarWidget(
                    onSettingsTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                    onFormatTap: () {
                       // Basic format simulation for now (or integrate dart_style if available)
                       final current = _codeController.text;
                       // We can try to use dart_style here if we add it, for now just simple replace
                       _codeController.text = current.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    },
                  ),
                  const EditorTabs(),
                  _buildStdinInput(),
                  Expanded(
                    child: _buildEditor(),
                  ),
                  const SizedBox(height: 100), // Space for output sheet handle
                ],
              ),
              const OutputSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isRunning) {
    return Container(
      height: 56,
      color: AppTheme.appBarColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
            ),
            onPressed: isRunning
                ? null
                : () {
                    ref.read(stdinProvider.notifier).state = _stdinController.text;
                    ref.read(executionProvider.notifier).runCode(_codeController.text);
                  },
            icon: isRunning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.play_arrow),
            label: const Text('Run'),
          )
        ],
      ),
    );
  }

  Widget _buildStdinInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: TextField(
        controller: _stdinController,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Standard Input (stdin) ...',
          hintStyle: const TextStyle(color: Colors.white38),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.white24)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.primaryYellow)),
        ),
        onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
      ),
    );
  }

  Widget _buildEditor() {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _codeController,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.white38),
            showLineNumbers: true,
          ),
        ),
      ),
    );
  }
}
