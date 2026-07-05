import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/compiler_provider.dart';
import 'widgets/toolbar.dart';
import 'widgets/editor_widget.dart';
import 'widgets/tab_bar_widget.dart';
import 'widgets/output_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _runCode() {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.activePreset;

    ref.read(executionProvider.notifier).executeCode(
      preset,
      activeFile.content,
    );

    // Show output sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OutputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
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
                style: TextStyle(
                  color: AppTheme.pureBlack,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : _runCode,
              icon: execState.isRunning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureBlack))
                : const Icon(Icons.play_arrow, size: 20),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            const EditorToolbar(),
            const TabBarWidget(),
            const Expanded(
              child: EditorWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
