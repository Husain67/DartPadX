import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/providers/execution_provider.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';
import 'package:dart_mini_ide/providers/settings_provider.dart';
import 'package:dart_mini_ide/ui/widgets/code_editor.dart';
import 'package:dart_mini_ide/ui/widgets/output_sheet.dart';
import 'package:dart_mini_ide/ui/widgets/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);
    final fileState = ref.watch(fileProvider);
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context, ref, executionState.isExecuting, fileState, settingsState),
                  const Toolbar(),
                  const Expanded(child: CodeEditor()),
                  // Spacing for BottomSheet handle
                  const SizedBox(height: 30),
                ],
              ),
              _buildBottomSheet(context, ref, executionState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, bool isExecuting, FileState fileState, SettingsState settingsState) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black,
      child: Row(
        children: [
          const Text(
            'DartMini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
              'beta',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Run Button
          if (fileState.activeFile != null)
            GestureDetector(
              onTap: isExecuting
                  ? null
                  : () {
                      final file = fileState.activeFile!;
                      final preset = settingsState.useCustomPreset ? settingsState.activePreset : null;
                      // TODO: Get stdin from somewhere? Maybe prompted or from output sheet input?
                      // For now empty stdin. Or I can implement stdin input in OutputSheet.
                      ref.read(executionProvider.notifier).execute(file, "", preset: preset);
                    },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: isExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
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
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, WidgetRef ref, ExecutionState state) {
    return DraggableScrollableSheet(
      initialChildSize: state.outputVisible ? 0.4 : 0.08,
      minChildSize: 0.08,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: OutputSheet(scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}
