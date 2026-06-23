import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/file_tabs.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import '../widgets/keyboard_shortcuts_handler.dart';
import 'package:dart_style/dart_style.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final isExecuting = ref.watch(executionProvider).isExecuting;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: MainAppBar(
        isRunning: isExecuting,
        onRunPressed: () {
          // For now, stdin is empty. A real implementation might prompt or use a settings field.
          ref.read(executionProvider.notifier).runCode('');
        },
      ),
      body: KeyboardShortcutsHandler(
      onSave: () => Fluttertoast.showToast(msg: "Saved (Auto-save is also active)", backgroundColor: Colors.green),
      onRun: () => ref.read(executionProvider.notifier).runCode(""),
      onFormat: () {
        final activeFile = ref.read(fileProvider).activeFile;
        if (activeFile != null) {
          try {
            final formattedCode = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion).format(activeFile.content);
            ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
          } catch (_) {}
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              EditorToolbar(
                onNewFile: () => ref.read(fileProvider.notifier).createNewFile(),
                onImport: () => _importFile(ref),
                onCopy: () => _copyCode(ref),
                onPaste: () => _pasteCode(ref),
                onDownload: () => _downloadFile(ref),
                onShare: () => _shareCode(ref),
                onDelete: () => _deleteFile(context, ref),
                onSettings: () => _openSettings(context),
              ),
              const FileTabs(),
              Expanded(
                child: fileState.activeFile != null
                    ? CodeEditorWidget(
                        key: ValueKey(fileState.activeFileId), // Force rebuild on file switch
                        initialContent: fileState.activeFile!.content,
                        onChanged: (content) {
                          ref.read(fileProvider.notifier).updateActiveFileContent(content);
                        },
                      )
                    : const Center(
                        child: Text(
                          'No file selected.\nCreate or open a file to start coding.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
              ),
              const SizedBox(height: 60), // Space for bottom sheet handle
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = utf8.decode(result.files.single.bytes!);
        String name = result.files.single.name;
        ref.read(fileProvider.notifier).importFile(name, content);
        Fluttertoast.showToast(msg: 'Imported $name successfully', backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error importing file', backgroundColor: Colors.red);
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard', backgroundColor: const Color(0xFFFACC15), textColor: Colors.black);
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        final currentContent = activeFile.content;
        // In a real app, we'd insert at cursor. For now, replace.
        ref.read(fileProvider.notifier).updateActiveFileContent(data!.text!);
        Fluttertoast.showToast(msg: 'Code pasted', backgroundColor: const Color(0xFFFACC15), textColor: Colors.black);
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    // In web, you can use anchor element. In mobile, need path_provider.
    // For simplicity, we just copy to clipboard for now as a fallback or show toast.
    Fluttertoast.showToast(msg: 'File download simulated. Use Share to export on mobile.', backgroundColor: const Color(0xFFFACC15), textColor: Colors.black);
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Check out my Dart code!');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeId = ref.read(fileProvider).activeFileId;
    if (activeId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Delete this file?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeId);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'File deleted', backgroundColor: Colors.redAccent);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
