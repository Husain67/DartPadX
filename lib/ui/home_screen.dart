import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import 'widgets/toolbar.dart';
import 'widgets/file_tabs.dart';
import 'widgets/editor_widget.dart';
import 'widgets/output_sheet.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/compiler_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _stdinCtrl = TextEditingController();

  void _runCode(WidgetRef ref) {
    final fileState = ref.read(fileProvider);
    final activeFileId = fileState.activeFileId;
    if (activeFileId == null) return;

    final activeFile = fileState.files.firstWhere((f) => f.id == activeFileId);

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.presets.firstWhere((p) => p.id == compilerState.activePresetId);

    ref.read(executionProvider.notifier).executeCode(activeFile.content, _stdinCtrl.text, preset);
  }

  void _showStdinDialog() {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text('Standard Input (stdin)'),
              content: TextField(
                  controller: _stdinCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      hintText: 'Enter stdin data here...',
                      border: OutlineInputBorder(),
                  ),
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save & Close')),
              ]
          )
      );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(executionProvider).isRunning;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(color: AppTheme.pureBlack, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.input),
                tooltip: 'Set Stdin',
                onPressed: _showStdinDialog,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: isRunning ? null : () => _runCode(ref),
                icon: isRunning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.pureBlack, strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const Toolbar(),
                const FileTabs(),
                Expanded(
                  child: EditorWidget(),
                ),
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }
}
