import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_style/dart_style.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar.dart';
import '../widgets/file_tabs.dart';
import '../widgets/editor_area.dart';
import '../widgets/output_sheet.dart';
import '../utils/theme.dart';
import '../utils/file_actions.dart';
import 'settings_screen.dart';
import '../widgets/examples_dialog.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final isRunning = ref.watch(executionProvider).isRunning;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgDarkStart, AppTheme.bgDarkEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // App Bar
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('DartMini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentYellow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: isRunning ? null : () => ref.read(executionProvider.notifier).executeCode(),
                          icon: isRunning
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.play_arrow, color: Colors.black),
                          label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentYellow,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toolbar
                  Toolbar(
                    onNewFile: () => ref.read(fileProvider.notifier).addFile(),
                    onImport: () async {
                      final content = await FileActions.importFile();
                      if (content != null) {
                        ref.read(fileProvider.notifier).addFile(name: 'imported.dart', content: content);
                      }
                    },
                    onCopy: () {
                      final content = ref.read(fileProvider.notifier).activeFile?.content ?? '';
                      FileActions.copyToClipboard(content);
                    },
                    onPaste: () async {
                      final text = await FileActions.pasteFromClipboard();
                      if (text != null) {
                        ref.read(fileProvider.notifier).updateActiveContent(text, forceSync: true);
                      }
                    },
                    onDownload: () {
                      final active = ref.read(fileProvider.notifier).activeFile;
                      if (active != null) {
                        FileActions.downloadFile(active.name, active.content);
                      }
                    },
                    onShare: () {
                      final content = ref.read(fileProvider.notifier).activeFile?.content ?? '';
                      FileActions.shareAsDeepLink(content);
                    },
                    onDelete: () => _confirmDelete(context, ref),
                    onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    onExamples: () => showDialog(context: context, builder: (_) => const ExamplesDialog()),
                  ),
                  const FileTabs(),
                  Expanded(
                    child: fileState.files.isEmpty
                      ? const Center(child: Text('No files opened.', style: TextStyle(color: Colors.white54)))
                      : const EditorArea(),
                  ),
                  const SizedBox(height: 60), // Space for output sheet handle
                ],
              ),
              const OutputSheet(),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above sheet
        child: FloatingActionButton(
          mini: true,
          backgroundColor: AppTheme.accentYellow,
          onPressed: () {
             final active = ref.read(fileProvider.notifier).activeFile;
             if (active != null) {
               try {
                 final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                 final formatted = formatter.format(active.content);
                 ref.read(fileProvider.notifier).updateActiveContent(formatted, forceSync: true);
               } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syntax error. Cannot format.')));
               }
             }
          },
          child: const Icon(Icons.format_align_left, color: Colors.black),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted successfully.')));
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
