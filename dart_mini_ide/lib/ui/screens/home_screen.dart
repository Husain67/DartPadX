import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/execution_provider.dart';
import '../widgets/toolbar.dart';
import '../widgets/code_editor.dart';
import '../widgets/output_sheet.dart';
import '../widgets/file_tabs.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<CodeEditorState> _editorKey = GlobalKey<CodeEditorState>();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    ref.listen(executionProvider, (prev, next) {
      if (!next.isLoading && (next.result != null || next.error != null)) {
        if (_sheetController.isAttached) {
             if (_sheetController.size < 0.4) {
               _sheetController.animateTo(
                 0.5,
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeOut,
               );
             }
        }
      }
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            children: [
              const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildRunButton(ref),
            ),
          ],
        ),
        body: Column(
          children: [
            Toolbar(editorKey: _editorKey),
            const FileTabs(),
            Expanded(
              child: CodeEditor(key: _editorKey),
            ),
          ],
        ),
        bottomSheet: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
             return true;
          },
          child: DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.08,
            minChildSize: 0.08,
            maxChildSize: 0.85,
            snap: true,
            builder: (context, scrollController) {
              return OutputSheet(scrollController: scrollController);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRunButton(WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return InkWell(
      onTap: executionState.isLoading ? null : () {
        final code = _editorKey.currentState?.currentCode;
        if (code != null) {
           // We pass empty string for stdin for now as prompt didn't specify input UI
           ref.read(executionProvider.notifier).execute(code, "");
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.accentYellow,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: executionState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Row(
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Run',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
