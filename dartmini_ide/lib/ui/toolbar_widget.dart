import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/providers.dart';
import 'package:dart_style/dart_style.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildBtn(context, 'New File', Icons.insert_drive_file, () => _newFile(context, ref)),
          _buildBtn(context, 'Import', Icons.file_download, () => _importFile(ref)),
          _buildBtn(context, 'Examples', Icons.lightbulb, () => _openExamples(context)),
          _buildBtn(context, 'Format', Icons.format_align_left, () => _formatCode(ref)),
          _buildBtn(context, 'Copy', Icons.copy, () => _copyCode(ref)),
          _buildBtn(context, 'Paste', Icons.paste, () => _pasteCode(ref)),
          _buildBtn(context, 'Download', Icons.download, () => _downloadFile(ref)),
          _buildBtn(context, 'Share', Icons.share, () => _shareCode(ref)),
          _buildBtn(context, 'Delete', Icons.delete, () => _deleteFile(context, ref)),
          _buildBtn(context, 'Settings', Icons.settings, () => _openSettings(context)),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(
            side: BorderSide(color: Colors.grey, width: 0.5),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }

  void _openExamples(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExamplesScreen()),
    );
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formattedCode = formatter.format(activeFile.content);
        ref.read(filesProvider.notifier).updateActiveFileContent(formattedCode);
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Syntax error, cannot format');
      }
    }
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    int count = ref.read(filesProvider).files.length + 1;
    ref.read(filesProvider.notifier).addFile('untitled_$count.dart', '');
    Fluttertoast.showToast(msg: 'New file created');
  }

  Future<void> _importFile(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        final content = utf8.decode(file.bytes!);
        ref.read(filesProvider.notifier).addFile(file.name, content);
        Fluttertoast.showToast(msg: 'File imported');
      }
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final activeFile = ref.read(filesProvider).activeFile;
      if (activeFile != null) {
        ref.read(filesProvider.notifier).updateActiveFileContent(activeFile.content + data.text!);
        Fluttertoast.showToast(msg: 'Code pasted');
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final file = File('${dir.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: 'Saved to ${file.path}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error saving file: $e');
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Shared from DartMini IDE');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
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
          TextButton(
            onPressed: () {
              ref.read(filesProvider.notifier).removeActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
