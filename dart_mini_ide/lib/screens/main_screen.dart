import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/compiler_provider.dart';
import '../screens/settings_screen.dart';
import '../widgets/editor_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/output_sheet.dart';
import '../widgets/file_tabs.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _stdinController = TextEditingController();

  void _runCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    // Focus on output sheet conceptually (expand it)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.1,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return OutputSheet(scrollController: controller);
        },
      ),
    );

    ref.read(executionProvider.notifier).executeCode(
      activeFile.content,
      _stdinController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider).activeFile;
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 255 * 0.2), // Yellow with alpha (formerly opacity)
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFACC15)),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: executionState.isLoading ? null : _runCode,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    if (executionState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                    const SizedBox(width: 4),
                    const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const ToolbarWidget(),
            const FileTabs(),
            Expanded(
              child: activeFile == null
                  ? const Center(child: Text('No file open', style: TextStyle(color: Colors.white54)))
                  : EditorWidget(key: ValueKey(activeFile.id), file: activeFile),
            ),
          ],
        ),
      ),
    );
  }
}
