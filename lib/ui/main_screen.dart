

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_file.dart';


import '../providers/file_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/theme.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _runCode() async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final settingsState = ref.read(settingsProvider);
    final stdinStr = ref.read(stdinProvider);

    await ref.read(executionProvider.notifier).executeCode(
      code: activeFile.content,
      stdin: stdinStr,
      settingsState: settingsState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    // Sync editor with active file
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != previous?.activeFileId || previous?.activeFile?.content != next.activeFile?.content) {
          if (next.activeFile != null && _codeController.text != next.activeFile!.content) {
             final currentSelection = _codeController.selection;
             _codeController.text = next.activeFile!.content;
             // Try to restore selection safely
             if (currentSelection.isValid && currentSelection.end <= _codeController.text.length) {
                 _codeController.selection = currentSelection;
             }
          }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
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
            padding: const EdgeInsets.only(right: 16.0),
            child: _RunButton(onRun: _runCode),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _Toolbar(),
            _FileTabs(fileState: fileState),
            Expanded(
              child: activeFile == null
                  ? const Center(child: Text('No files open.'))
                  : CodeTheme(
                      data: CodeThemeData(styles: draculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(color: Colors.white54, height: 1.5),
                            width: 48,
                          ),
                          background: AppTheme.backgroundColor,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: const _OutputSheet(),
    );
  }
}

class _RunButton extends ConsumerWidget {
  final VoidCallback onRun;
  const _RunButton({required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return ElevatedButton(
      onPressed: execState.isLoading ? null : onRun,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: execState.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            )
          : const Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.black),
                SizedBox(width: 4),
                Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }
}


class _Toolbar extends ConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _ToolbarButton(icon: Icons.add, label: 'New', onTap: () {
             ref.read(fileProvider.notifier).addFile(AppFile(name: 'untitled.dart', content: ''));
          }),
          _ToolbarButton(icon: Icons.file_download, label: 'Import', onTap: () async {
             try {
               FilePickerResult? result = await FilePicker.platform.pickFiles(
                 type: FileType.custom,
                 allowedExtensions: ['dart', 'txt'],
               );
               if (result != null && result.files.single.path != null) {
                 final file = File(result.files.single.path!);
                 final content = await file.readAsString();
                 ref.read(fileProvider.notifier).addFile(AppFile(name: result.files.single.name, content: content));
               }
             } catch (e) {
               Fluttertoast.showToast(msg: "Error importing file: \$e");
             }
          }),
          _ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: () {
             final activeFile = ref.read(fileProvider).activeFile;
             if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Code copied!");
             }
          }),
          _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: () async {
             final activeFile = ref.read(fileProvider).activeFile;
             if (activeFile == null) return;
             final data = await Clipboard.getData(Clipboard.kTextPlain);
             if (data != null && data.text != null) {
                final newContent = activeFile.content + data.text!;
                ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
                ref.read(fileProvider.notifier).triggerUIRefresh();
                Fluttertoast.showToast(msg: "Pasted!");
             }
          }),
          _ToolbarButton(icon: Icons.download, label: 'Download', onTap: () async {
             final activeFile = ref.read(fileProvider).activeFile;
             if (activeFile == null) return;
             try {
                final directory = await getApplicationDocumentsDirectory();
                final path = "${directory.path}/${activeFile.name}";
                final file = File(path);
                await file.writeAsString(activeFile.content);
                Fluttertoast.showToast(msg: "Saved to \$path");
             } catch (e) {
                Fluttertoast.showToast(msg: "Error saving: \$e");
             }
          }),
          _ToolbarButton(icon: Icons.share, label: 'Share', onTap: () {
             final activeFile = ref.read(fileProvider).activeFile;
             if (activeFile == null) return;
             final base64Code = base64Encode(utf8.encode(activeFile.content));
             Share.share('Check out my Dart code! dartmini://code?b64=$base64Code');
          }),
          _ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: () {
             final activeFileId = ref.read(fileProvider).activeFileId;
             if (activeFileId == null) return;
             showDialog(context: context, builder: (_) => AlertDialog(
               title: const Text('Delete this file?'),
               content: const Text('This cannot be undone.'),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                 TextButton(
                   onPressed: () {
                     ref.read(fileProvider.notifier).deleteFile(activeFileId);
                     Navigator.pop(context);
                     Fluttertoast.showToast(msg: "File deleted");
                   },
                   child: const Text('Delete', style: TextStyle(color: Colors.red)),
                 ),
               ],
             ));
          }),
          _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }
}
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTabs extends ConsumerWidget {
  final FileState fileState;
  const _FileTabs({required this.fileState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 40,
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () {
               ref.read(fileProvider.notifier).forceSaveActiveFile();
               ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundColor : AppTheme.surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                       ref.read(fileProvider.notifier).deleteFile(file.id);
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OutputSheet extends ConsumerWidget {
  const _OutputSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (execState.executionTime.isNotEmpty)
                      Text('Time: ${execState.executionTime}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (execState.error.isNotEmpty)
                      Text(execState.error, style: const TextStyle(color: AppTheme.errorColor, fontFamily: 'monospace'))
                    else if (execState.stderr.isNotEmpty)
                      Text(execState.stderr, style: const TextStyle(color: AppTheme.errorColor, fontFamily: 'monospace'))
                    else if (execState.stdout.isNotEmpty)
                      Text(execState.stdout, style: const TextStyle(color: AppTheme.successColor, fontFamily: 'monospace'))
                    else
                      const Text('Ready to run.', style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
