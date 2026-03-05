import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/execution_provider.dart';
import '../widgets/toolbar.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import '../widgets/editor_tabs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);
    final isExecuting = executionState.isExecuting;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                AppConstants.appVersion,
                style: TextStyle(
                  color: AppColors.pureBlack,
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
            child: Center(
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: isExecuting
                      ? null
                      : () => ref.read(executionProvider.notifier).executeCode(),
                  icon: isExecuting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureBlack),
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 20),
                  label: Text(isExecuting ? 'Running...' : 'Run'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(
                    height: AppConstants.toolbarButtonSize + 16,
                    child: ToolbarWidget(),
                  ),
                  const Divider(height: 1, color: AppColors.buttonBorder),
                  const EditorTabs(),
                  const Expanded(
                    child: CodeEditorWidget(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomSheet: const OutputSheet(),
    );
  }
}
