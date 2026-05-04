import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../services/file_service.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/output_sheet.dart';
import '../widgets/code_editor_view.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _stdinController = TextEditingController();

  void _runCode() {
    FocusScope.of(context).unfocus(); // hide keyboard
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      ref.read(executionProvider.notifier).executeCode(activeFile.content, _stdinController.text);
    }
  }

  void _showDeleteConfirmation() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted", backgroundColor: Colors.green);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(fileProvider.select((state) => state.files));
    final activeFileId = ref.watch(fileProvider.select((state) => state.activeFileId));
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isExecuting ? null : _runCode,
              icon: execState.isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toolbar
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  children: [
                    ToolbarButton(
                      icon: Icons.add,
                      label: 'New',
                      onTap: () => ref.read(fileProvider.notifier).createNewFile(),
                    ),
                    ToolbarButton(
                      icon: Icons.code,
                      label: 'Examples',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => ListView(
                            children: [
                              const ListTile(title: Text('Examples Gallery', style: TextStyle(fontWeight: FontWeight.bold))),
                              ListTile(
                                title: const Text('Hello World'),
                                onTap: () {
                                  ref.read(fileProvider.notifier).importFile('hello.dart', "void main() {\n  print('Hello World!');\n}");
                                  Navigator.pop(ctx);
                                },
                              ),
                              ListTile(
                                title: const Text('Async Example'),
                                onTap: () {
                                  ref.read(fileProvider.notifier).importFile('async.dart', "void main() async {\n  print('Waiting...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}");
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.file_download,
                      label: 'Import',
                      onTap: () async {
                        final content = await FileService().pickDartFile();
                        if (content != null) {
                          ref.read(fileProvider.notifier).importFile('imported.dart', content);
                        }
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.format_align_left,
                      label: 'Format',
                      onTap: () {
                         // A simple dummy format, real format requires dart_style package.
                         Fluttertoast.showToast(msg: "Formatted Code (mock)");
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.copy,
                      label: 'Copy',
                      onTap: () {
                        final content = ref.read(fileProvider.notifier).activeFile?.content;
                        if (content != null) {
                          Clipboard.setData(ClipboardData(text: content));
                          Fluttertoast.showToast(msg: "Copied to clipboard");
                        }
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.paste,
                      label: 'Paste',
                      onTap: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          ref.read(fileProvider.notifier).updateActiveFileContent(data!.text!);
                        }
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: () async {
                        final file = ref.read(fileProvider.notifier).activeFile;
                        if (file != null) {
                          final path = await FileService().saveDartFile(file.name, file.content);
                          if (path != null) {
                            Fluttertoast.showToast(msg: "Saved to \$path");
                          }
                        }
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () {
                        final file = ref.read(fileProvider.notifier).activeFile;
                        if (file != null) {
                          FileService().shareDartFile(file.name, file.content);
                        }
                      },
                    ),
                    ToolbarButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      onTap: _showDeleteConfirmation,
                    ),
                    ToolbarButton(
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
              ),

              // File Tabs
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isActive = file.id == activeFileId;
                    return GestureDetector(
                      onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? Theme.of(context).colorScheme.surface : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                ref.read(fileProvider.notifier).setActiveFile(file.id);
                                ref.read(fileProvider.notifier).deleteActiveFile();
                              },
                              child: Icon(Icons.close, size: 16, color: isActive ? Colors.white : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // STDIN input
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _stdinController,
                  decoration: InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),

              // Editor
              const Expanded(
                child: CodeEditorView(),
              ),
            ],
          ),

          // Bottom Sheet for Output
          const OutputSheet(),
        ],
      ),
    );
  }
}
