import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/execution_service.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';
import '../theme.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final FocusNode _focusNode = FocusNode();

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
    _focusNode.dispose();
    super.dispose();
  }

  void _runCode() async {
    final file = ref.read(fileProvider).files.firstWhere((f) => f.id == ref.read(fileProvider).activeFileId);
    final settings = ref.read(settingsProvider);

    ref.read(executionProvider.notifier).setLoadState(true);

    final result = await ExecutionService.runCode(
      code: file.content,
      useDefault: settings.useDefaultCompiler,
      preset: settings.useDefaultCompiler ? null : ref.read(settingsProvider.notifier).activePreset,
      defaultKey: settings.defaultApiKey,
    );

    ref.read(executionProvider.notifier).setResult(result);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        final activeFile = ref.read(fileProvider.notifier).activeFile;
        if (activeFile != null && _codeController.text != activeFile.content) {
          _codeController.text = activeFile.content;
        }
      } else if (previous != null) {
        final activeFile = ref.read(fileProvider.notifier).activeFile;
        if (activeFile != null && _codeController.text != activeFile.content) {
            final currentSelection = _codeController.selection;
            _codeController.text = activeFile.content;
            _codeController.selection = currentSelection;
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
                color: accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: execState.isLoading ? null : _runCode,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: execState.isLoading ? Colors.grey : accentYellow,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: execState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Row(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.black, size: 20),
                        SizedBox(width: 4),
                        Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            Column(
              children: [
                const MainToolbar(),
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
                            border: Border(bottom: BorderSide(color: isActive ? accentYellow : Colors.transparent, width: 2)),
                            color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: Text(file.name, style: TextStyle(color: isActive ? accentYellow : Colors.white70)),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: CodeTheme(
                    data: CodeThemeData(styles: monokaiSublimeTheme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: _codeController,
                        focusNode: _focusNode,
                        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        gutterStyle: const GutterStyle(showLineNumbers: true, textStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (execState.result != null || execState.isLoading)
              const OutputSheet(),
          ],
        ),
      ),
    );
  }
}
