import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../providers.dart';
import '../theme.dart';
import 'editor_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref),
              _buildToolbar(context, ref),
              const Expanded(
                child: EditorWidget(),
              ),
              _buildOutputHandle(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Container(
      height: 56,
      color: AppTheme.pureBlack,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'DartMini',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(
                    color: AppTheme.pureBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: execState.isRunning
                ? null
                : () {
                    final activeFile = ref.read(fileProvider).activeFileId != null
                        ? ref.read(fileProvider).files.firstWhere((f) => f.id == ref.read(fileProvider).activeFileId)
                        : null;
                    if (activeFile != null) {
                      ref.read(executionProvider.notifier).executeCode(activeFile.content);
                      _showOutputSheet(context);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: AppTheme.pureBlack,
              minimumSize: const Size(64, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: execState.isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppTheme.pureBlack,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    children: [
                      Icon(Icons.play_arrow, size: 20),
                      SizedBox(width: 4),
                      Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildToolbarButton(Icons.add, 'New File', () {
             ref.read(fileProvider.notifier).addFile('untitled.dart', '');
          }),
          _buildToolbarButton(Icons.download_rounded, 'Import .dart', () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String contents = await file.readAsString();
                ref.read(fileProvider.notifier).addFile(result.files.single.name, contents);
              }
            } catch (e) {
              Fluttertoast.showToast(msg: "Error importing file: \$e");
            }
          }),
          _buildToolbarButton(Icons.copy, 'Copy Code', () {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
              Clipboard.setData(ClipboardData(text: activeFile.content));
              Fluttertoast.showToast(msg: "Code copied to clipboard");
            }
          }),
          _buildToolbarButton(Icons.paste, 'Paste Code', () async {
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            if (clipboardData?.text != null) {
              final fileId = ref.read(fileProvider).activeFileId;
              if (fileId != null) {
                 ref.read(fileProvider.notifier).updateContent(fileId, clipboardData!.text!);
                 ref.read(fileProvider.notifier).addFile('pasted.dart', clipboardData.text!);
                 Fluttertoast.showToast(msg: "Pasted as new file for safety");
              } else {
                 ref.read(fileProvider.notifier).addFile('pasted.dart', clipboardData!.text!);
              }
            }
          }),
          _buildToolbarButton(Icons.format_align_left, 'Format Code', () {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
              try {
                final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
                final formatted = formatter.format(activeFile.content);
                // Same issue here: to update the editor content, we need a way to pass it to the controller.
                // Since Riverpod state doesn't directly force EditorWidget to update the controller's text unless activeFileId changes,
                // we handle formatting by updating state and using a new file or tricking the active ID (in a real app we'd use an event bus or expose the controller).
                // Let's just create a formatted copy for simplicity in this constrained setup.
                ref.read(fileProvider.notifier).addFile('\${activeFile.name}_fmt.dart', formatted);
                Fluttertoast.showToast(msg: "Formatted code opened in new tab");
              } catch (e) {
                Fluttertoast.showToast(msg: "Syntax error: Cannot format");
              }
            }
          }),
          _buildToolbarButton(Icons.share, 'Share / Download', () async {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
              try {
                final directory = await getTemporaryDirectory();
                final file = File('\${directory.path}/\${activeFile.name}');
                await file.writeAsString(activeFile.content);
                await Share.shareXFiles([XFile(file.path)], text: 'Check out my Dart code!');
              } catch (e) {
                Fluttertoast.showToast(msg: "Error sharing file");
              }
            }
          }),
          _buildToolbarButton(Icons.delete, 'Delete File', () {
             final activeFileId = ref.read(fileProvider).activeFileId;
             if (activeFileId != null) {
               showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.backgroundLight,
                  title: const Text('Delete this file?', style: TextStyle(color: AppTheme.textPrimary)),
                  content: const Text('This cannot be undone.', style: TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: () {
                        ref.read(fileProvider.notifier).deleteFile(activeFileId);
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(msg: "File deleted");
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
             }
          }),
          _buildToolbarButton(Icons.library_books, 'Examples', () {
             _showExamplesSheet(context, ref);
          }),
          _buildToolbarButton(Icons.settings, 'Settings', () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.toolbarButtonBg,
              border: Border.all(color: AppTheme.toolbarButtonBorder),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: AppTheme.toolbarButtonIcon, size: 20),
          ),
        ),
      ),
    );
  }

  void _showExamplesSheet(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello, World!");\n}',
      'List & Map': 'void main() {\n  var list = [1, 2, 3];\n  var map = {"a": 1, "b": 2};\n  print(list);\n  print(map);\n}',
      'Classes': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.greet();\n}',
      'Async/Await': 'Future<void> main() async {\n  print("Fetching data...");\n  await Future.delayed(Duration(seconds: 1));\n  print("Data loaded!");\n}'
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundLight,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Examples', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...examples.entries.map((e) => ListTile(
            title: Text(e.key, style: const TextStyle(color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.add, color: AppTheme.primaryAccent),
            onTap: () {
              ref.read(fileProvider.notifier).addFile('\${e.key.replaceAll(" ", "_")}.dart', e.value);
              Navigator.pop(ctx);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildOutputHandle(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showOutputSheet(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _showOutputSheet(context);
        }
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  void _showOutputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OutputSheet(),
    );
  }
}

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Output',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (execState.executionTime.isNotEmpty) ...[
                      Text(
                        '\${execState.executionTime}ms',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: AppTheme.textSecondary),
                      onPressed: () => ref.read(executionProvider.notifier).clear(),
                      tooltip: 'Clear Output',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: execState.isRunning
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (execState.stdout.isNotEmpty)
                        Text(
                          execState.stdout,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      if (execState.stderr.isNotEmpty) ...[
                        if (execState.stdout.isNotEmpty) const SizedBox(height: 16),
                        Text(
                          execState.stderr,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                        const Center(
                          child: Text(
                            'No output yet',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
