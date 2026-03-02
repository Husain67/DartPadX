import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../providers/file_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import 'widgets/toolbar.dart';
import 'widgets/file_tabs.dart';
import 'widgets/editor_widget.dart';
import 'widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
      if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyR) {
        _runCode(ref);
      } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
        ref.read(fileProvider.notifier).formatActiveFile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);
    final isExecuting = execState.isExecuting;

    return Scaffold(
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
            padding: const EdgeInsets.only(right: 16.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isExecuting ? null : () => _runCode(ref),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isExecuting ? Colors.grey : AppTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isExecuting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isExecuting ? 'Running...' : 'Run',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: SafeArea(
            child: Stack(
              children: [
                const Column(
                  children: [
                    IDEToolbar(),
                    FileTabs(),
                    Expanded(child: EditorWidget()),
                  ],
                ),
                const OutputSheet(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _runCode(WidgetRef ref) {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null || activeFile.content.trim().isEmpty) {
      return;
    }

    final settings = ref.read(settingsProvider);
    final preset = settings.useDefaultCompiler ? null : settings.selectedPreset;

    ref.read(executionProvider.notifier).executeCode(activeFile.content, preset);
  }
}
