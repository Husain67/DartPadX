import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/toolbar.dart';
import '../widgets/code_editor.dart';
import '../widgets/output_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(AppConstants.appName),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                AppConstants.appVersion,
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
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: execState.isRunning
                  ? null
                  : () {
                      ref.read(executionProvider.notifier).executeCode();
                    },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    if (execState.isRunning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    else
                      const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'Run',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: const [
                  ToolbarWidget(),
                  Expanded(child: CodeEditorWidget()),
                ],
              ),
              // Draggable Output Sheet overlay
              const Align(
                alignment: Alignment.bottomCenter,
                child: OutputSheetWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
