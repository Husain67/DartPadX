import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';
import 'package:dart_mini_ide/features/editor/widgets/editor_toolbar.dart';
import 'package:dart_mini_ide/features/editor/widgets/code_editor_view.dart';
import 'package:dart_mini_ide/features/editor/widgets/file_tabs.dart';
import 'package:dart_mini_ide/shared/widgets/output_console.dart';
import 'package:dart_mini_ide/features/execution/providers/execution_provider.dart';
import 'package:dart_mini_ide/features/settings/providers/settings_provider.dart';
import 'package:dart_mini_ide/features/editor/providers/editor_provider.dart';
import 'package:dart_mini_ide/core/models/compiler_preset.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);
    final editorState = ref.watch(editorProvider);
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // AppBar
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'DartMini',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                        Material(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: executionState.isLoading
                                ? null
                                : () {
                                    if (editorState.activeFile != null) {
                                      CompilerPreset? preset;
                                      final presetId = settingsState.activePresetId;

                                      if (presetId != null) {
                                        try {
                                          preset = settingsState.presets.firstWhere((p) => p.id == presetId);
                                        } catch (_) {
                                          // Preset not found, fallback to default? or show error?
                                          // Usually implies data inconsistency.
                                          // We will pass null (default OneCompiler)
                                        }
                                      }

                                      final stdinValue = ref.read(stdinProvider);

                                      ref.read(executionProvider.notifier).runCode(
                                        editorState.activeFile!.content,
                                        preset: preset,
                                        stdin: stdinValue,
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              alignment: Alignment.center,
                              child: executionState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                                    )
                                  : const Row(
                                      children: [
                                        Icon(Icons.play_arrow, color: Colors.black, size: 24),
                                        SizedBox(width: 4),
                                        Text(
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
                  ),
                  // Toolbar
                  const EditorToolbar(),
                  // File Tabs
                  const FileTabs(),
                  // Editor
                  const Expanded(
                    child: CodeEditorView(),
                  ),
                  // Space for BottomSheet handle
                  const SizedBox(height: 50),
                ],
              ),
              // Draggable Bottom Sheet
              DraggableScrollableSheet(
                initialChildSize: 0.1,
                minChildSize: 0.08,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  return OutputConsole(scrollController: scrollController);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
