import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/file_provider.dart';
import '../../providers/compiler_provider.dart';
import '../../providers/execution_provider.dart';
import '../../services/compiler_service.dart';
import '../theme.dart';
import '../widgets/editor_tabs.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import '../widgets/toolbar.dart';
import '../widgets/dialogs.dart';
import '../widgets/examples_dialog.dart';

import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  Future<void> _executeCode(BuildContext context, WidgetRef ref) async {
    final fileNotifier = ref.read(fileProvider.notifier);
    final activeFile = fileNotifier.activeFile;
    if (activeFile == null) return;

    final compilerState = ref.read(compilerProvider);
    final preset = ref.read(compilerProvider.notifier).activePreset;

    if (preset == null) {
      Fluttertoast.showToast(msg: "No compiler preset found!");
      return;
    }

    ref.read(executionProvider.notifier).setRunning(true);
    final stdinStr = ref.read(stdinProvider);

    final result = await CompilerService.executeCode(
      preset: preset,
      code: activeFile.content,
      stdin: stdinStr,
      language: activeFile.language,
    );

    ref.read(executionProvider.notifier).setResult(
      stdout: result.stdout,
      stderr: result.stderr,
      error: result.error,
      executionTime: result.executionTime,
      memory: result.memory,
    );
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  void _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      if (activeFile != null) {
        final newContent = activeFile.content + data.text!;
        ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
        ref.read(fileProvider.notifier).forceUpdate(); // trigger rebuild
      }
    }
  }

  void _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final path = '${dir!.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: 'Saved to $path');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Download failed: $e');
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: activeFile.name);
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;
    final confirm = await Dialogs.showConfirmDeleteDialog(context, activeFile.name);
    if (confirm == true) {
      await ref.read(fileProvider.notifier).deleteActiveFile();
      Fluttertoast.showToast(msg: 'File deleted');
    }
  }

  void _importFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['dart']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;

        final newFile = FileModel(
          id: const Uuid().v4(),
          name: name,
          content: content,
        );
        ref.read(fileProvider.notifier).addFile(newFile);
        Fluttertoast.showToast(msg: 'File imported');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Import failed: $e');
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        ref.read(fileProvider.notifier).forceUpdate();
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Format error: check syntax');
      }
    }
  }

  void _showExamples(BuildContext context) {
    showDialog(context: context, builder: (_) => const ExamplesDialog());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(executionProvider).isRunning;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
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
        actions: [
          Container(
            width: 100,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'stdin...',
                hintStyle: TextStyle(color: Colors.white54),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
              ),
              onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isRunning
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow))
                : TextButton.icon(
                    onPressed: () => _executeCode(context, ref),
                    icon: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
                    label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.accentYellow,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toolbar
              Container(
                height: 60,
                color: Colors.black,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  children: [
                    ToolbarButton(icon: Icons.add, tooltip: 'New File', onPressed: () => ref.read(fileProvider.notifier).createFile()),
                    ToolbarButton(icon: Icons.file_download, tooltip: 'Import .dart', onPressed: () => _importFile(ref)),
                    ToolbarButton(icon: Icons.copy, tooltip: 'Copy Code', onPressed: () => _copyCode(ref)),
                    ToolbarButton(icon: Icons.paste, tooltip: 'Paste Code', onPressed: () => _pasteCode(ref)),
                    ToolbarButton(icon: Icons.format_align_left, tooltip: 'Format Code', onPressed: () => _formatCode(ref)),
                    ToolbarButton(icon: Icons.lightbulb, tooltip: 'Examples', onPressed: () => _showExamples(context)),
                    ToolbarButton(icon: Icons.download, tooltip: 'Download', onPressed: () => _downloadFile(ref)),
                    ToolbarButton(icon: Icons.share, tooltip: 'Share', onPressed: () => _shareCode(ref)),
                    ToolbarButton(icon: Icons.delete, tooltip: 'Delete File', onPressed: () => _deleteFile(context, ref)),
                    ToolbarButton(icon: Icons.settings, tooltip: 'Settings', onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),
              const EditorTabs(),
              const Expanded(child: CodeEditorWidget()),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }
}
