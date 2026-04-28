import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_view.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

final stdinProvider = StateProvider<String>((ref) => '');

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(executionProvider).isRunning;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Examples',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamplesScreen())),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: isRunning ? null : () {
                final file = ref.read(fileProvider.notifier).activeFile;
                if (file != null) {
                  ref.read(fileProvider.notifier).forceSaveCurrent();
                  final stdinInput = ref.read(stdinProvider);
                  ref.read(executionProvider.notifier).runCode(file.content, stdin: stdinInput);
                } else {
                  Fluttertoast.showToast(msg: 'No active file to run', backgroundColor: Colors.red);
                }
              },
              icon: isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(isRunning ? 'Running' : 'Run', style: const TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Stack(
        children: [
          Column(
            children: [
              Toolbar(
                onNewFile: () => ref.read(fileProvider.notifier).addFile(),
                onImport: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['dart', 'txt'],
                    );
                    if (result != null && result.files.single.path != null) {
                      File file = File(result.files.single.path!);
                      String content = await file.readAsString();
                      ref.read(fileProvider.notifier).addFile(
                        name: result.files.single.name,
                        content: content,
                      );
                      Fluttertoast.showToast(msg: 'File imported', backgroundColor: Colors.green);
                    }
                  } catch (e) {
                     Fluttertoast.showToast(msg: 'Failed to import file', backgroundColor: Colors.red);
                  }
                },
                onCopy: () {
                  final file = ref.read(fileProvider.notifier).activeFile;
                  if (file != null) {
                    Clipboard.setData(ClipboardData(text: file.content));
                    Fluttertoast.showToast(msg: 'Code copied to clipboard', backgroundColor: Colors.green);
                  }
                },
                onPaste: () async {
                  final file = ref.read(fileProvider.notifier).activeFile;
                  if (file != null) {
                    ClipboardData? data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                       final newContent = file.content + data.text!;
                       ref.read(fileProvider.notifier).updateActiveFileContent(newContent, forceSave: true);
                    }
                  }
                },
                onDownload: () async {
                   final file = ref.read(fileProvider.notifier).activeFile;
                   if (file != null) {
                     try {
                        Directory? dir = await getExternalStorageDirectory();
                        dir ??= await getApplicationDocumentsDirectory();
                        final path = '${dir.path}/${file.name}';
                        final f = File(path);
                        await f.writeAsString(file.content);
                        Fluttertoast.showToast(msg: 'Saved to $path', backgroundColor: Colors.green, toastLength: Toast.LENGTH_LONG);
                     } catch(e) {
                        Fluttertoast.showToast(msg: 'Download failed', backgroundColor: Colors.red);
                     }
                   }
                },
                onShare: () {
                   final file = ref.read(fileProvider.notifier).activeFile;
                   if (file != null) {
                     final encoded = base64Encode(utf8.encode(file.content));
                     Share.share('Check out my Dart code on DartMini:\n\ndartmini://code?data=$encoded');
                   }
                },
                onDelete: () {
                   final file = ref.read(fileProvider.notifier).activeFile;
                   if (file == null) return;

                   showDialog(
                     context: context,
                     builder: (c) => AlertDialog(
                       title: const Text('Delete File?'),
                       content: const Text('This cannot be undone.'),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                         ElevatedButton(
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                           onPressed: () {
                             ref.read(fileProvider.notifier).deleteFile(file.id);
                             Navigator.pop(c);
                             Fluttertoast.showToast(msg: 'File deleted', backgroundColor: Colors.green);
                           },
                           child: const Text('Delete', style: TextStyle(color: Colors.white)),
                         )
                       ],
                     )
                   );
                },
                onSettings: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                onFormat: () {
                  final file = ref.read(fileProvider.notifier).activeFile;
                  if (file != null) {
                     try {
                       final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                       final formatted = formatter.format(file.content);
                       ref.read(fileProvider.notifier).updateActiveFileContent(formatted, forceSave: true);
                       Fluttertoast.showToast(msg: 'Code formatted', backgroundColor: Colors.green);
                     } catch (e) {
                       Fluttertoast.showToast(msg: 'Syntax error, cannot format', backgroundColor: Colors.red);
                     }
                  }
                },
              ),
              const Expanded(child: EditorView()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Standard Input (stdin)...',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),
              const SizedBox(height: 60), // padding for output sheet handle
            ],
          ),
          const OutputSheet(),
        ],
      ),
      ),
    );
  }
}
