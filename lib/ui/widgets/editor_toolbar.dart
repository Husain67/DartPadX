import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../../providers/file_notifier.dart';
import 'action_button.dart';
import '../screens/settings_screen.dart';
import '../screens/examples_screen.dart';

class EditorToolbar extends ConsumerWidget {
  final CodeController? codeController;
  const EditorToolbar({super.key, this.codeController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ActionButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => _promptNewFile(context, ref),
          ),
          ActionButton(
            icon: Icons.auto_awesome,
            label: 'Format Code',
            onTap: () => _formatCode(ref),
          ),
          ActionButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExamplesScreen()),
              );
            },
          ),
          ActionButton(
            icon: Icons.file_download,
            label: 'Import .dart',
            onTap: () => _importFile(ref),
          ),
          ActionButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _copyCode(ref),
          ),
          ActionButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          ActionButton(
            icon: Icons.download,
            label: 'Download .dart',
            onTap: () => _downloadFile(ref),
          ),
          ActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          ActionButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () {
              final activeId = ref.read(fileProvider).activeFileId;
              if (activeId != null) {
                _confirmDelete(context, ref, activeId);
              }
            },
          ),
          ActionButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.content.isNotEmpty) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, formattedCode);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Syntax error, cannot format");
      }
    }
  }

  void _promptNewFile(BuildContext context, WidgetRef ref) {
    String name = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'filename.dart'),
          onChanged: (val) => name = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                if (!name.endsWith('.dart')) name += '.dart';
                ref.read(fileProvider.notifier).createFile(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;

        ref.read(fileProvider.notifier).createFile(name, content: content);
        Fluttertoast.showToast(msg: "File imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file: $e");
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        String newContent = activeFile.content + data.text!;
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, newContent);
        Fluttertoast.showToast(msg: "Code pasted");
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to: $path");
      } catch (e) {
        Fluttertoast.showToast(msg: "Error saving file: $e");
      }
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      Share.share('Check out my Dart code:\n\n${activeFile.content}\n\nBase64:\n$base64Code');
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(id);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
