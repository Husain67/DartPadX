import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_shell.dart';
import '../widgets/output_sheet.dart';
import '../utils/theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Material(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    final code = ref.read(fileProvider.notifier).activeFile?.content ?? '';
                    final settings = ref.read(settingsProvider);
                    if (settings.useOneCompiler) {
                      ref.read(executionProvider.notifier).executeCode(code, useOneCompiler: true);
                    } else {
                      final activePreset = settings.customPresets.firstWhere((p) => p.id == settings.activePresetId, orElse: () => settings.customPresets.first);
                      ref.read(executionProvider.notifier).executeCode(code, useOneCompiler: false, preset: activePreset);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ref.watch(executionProvider).isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Row(
                            children: [
                              Icon(Icons.play_arrow, color: Colors.black, size: 20),
                              SizedBox(width: 4),
                              Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: const Stack(
          children: [
            Column(
              children: [
                MainToolbar(),
                Expanded(child: EditorShell()),
              ],
            ),
            OutputSheet(),
          ],
        ),
      ),
    );
  }
}
