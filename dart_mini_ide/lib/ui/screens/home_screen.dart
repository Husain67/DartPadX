import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/toolbar.dart';
import '../widgets/file_tabs.dart';
import '../widgets/code_editor.dart';
import '../widgets/output_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);
    final fileState = ref.watch(fileProvider);
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DartMini',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          RunButton(
            isLoading: execState.isLoading,
            onTap: () {
              if (fileState.currentFile != null) {
                ref.read(executionProvider.notifier).execute(
                  fileState.currentFile!,
                  settingsState.selectedPreset,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Toolbar(),
              SizedBox(height: 48, child: const FileTabs()),
              Expanded(child: const CodeEditor()),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }
}
