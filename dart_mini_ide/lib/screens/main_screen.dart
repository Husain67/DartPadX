import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_tabs.dart';
import '../widgets/editor_view.dart';
import '../widgets/output_sheet.dart';
import '../utils/format_utils.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _stdinController = TextEditingController();

  @override
  void dispose() {
    _stdinController.dispose();
    super.dispose();
  }

  void _runCode() {
    final execState = ref.read(executionProvider);
    if (execState.isExecuting) return;

    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile != null) {
      ref.read(executionProvider.notifier).executeCode(
        activeFile.content,
        stdin: _stdinController.text,
      );
    }
  }

  void _formatCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        String formatted = FormatUtils.formatDartCode(activeFile.content);
        ref.read(fileProvider.notifier).updateContent(formatted);
      } catch (e) {
        // Syntax error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isCtrlOrCmd = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                              HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                              HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                              HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);

          if (isCtrlOrCmd) {
            if (event.logicalKey == LogicalKeyboardKey.keyR) {
              _runCode();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
              _formatCode();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
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
                  color: AppTheme.primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryYellow),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Consumer(
                builder: (context, ref, child) {
                  final execState = ref.watch(executionProvider);
                  return ElevatedButton(
                    onPressed: execState.isExecuting ? null : _runCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.pureBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: execState.isExecuting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.pureBlack),
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, size: 20),
                              SizedBox(width: 4),
                              Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
            ),
          ),
          child: Column(
            children: [
              const Toolbar(),
              const EditorTabs(),
              const Expanded(
                child: EditorView(),
              ),
              Container(
                color: AppTheme.backgroundStart,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _stdinController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'STDIN (optional inputs)',
                    labelStyle: TextStyle(color: Colors.white54),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryYellow)),
                  ),
                ),
              ),
              const OutputSheet(),
            ],
          ),
        ),
      ),
    );
  }
}
