import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../providers/file_provider.dart';
import 'settings_screen.dart';
import 'examples_dialog.dart';
import 'package:dart_style/dart_style.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarBtn(Icons.add, "New", () => _newFile(context, ref)),
          _buildToolbarBtn(Icons.library_books, "Examples", () => _showExamples(context)),
          _buildToolbarBtn(Icons.format_align_left, "Format", () => _formatCode(ref)),
          _buildToolbarBtn(Icons.download, "Import", () => _importFile(ref)),
          _buildToolbarBtn(Icons.copy, "Copy", () => _copyCode(ref)),
          _buildToolbarBtn(Icons.paste, "Paste", () => _pasteCode(ref)),
          _buildToolbarBtn(Icons.file_download, "Download", () => _downloadFile(ref)),
          _buildToolbarBtn(Icons.share, "Share", () => _shareCode(ref)),
          _buildToolbarBtn(Icons.delete, "Delete", () => _deleteFile(context, ref)),
          _buildToolbarBtn(Icons.settings, "Settings", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildToolbarBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.black87),
        label: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF1F5F9), // White/Creamish
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white24, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
      ),
    );
  }


  void _showExamples(BuildContext context) {
    showDialog(context: context, builder: (_) => const ExamplesDialog());
  }

  void _formatCode(WidgetRef ref) {
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active != null) {
      try {
        final formatter = DartFormatter();
        final formatted = formatter.format(active.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        ref.read(fileProvider.notifier).triggerRebuild();
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Syntax error: Could not format code");
      }
    }
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    int counter = ref.read(fileProvider).files.length + 1;
    ref.read(fileProvider.notifier).addFile('untitled_$counter.dart', '');
    Fluttertoast.showToast(msg: "New file created");
  }

  Future<void> _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
      Fluttertoast.showToast(msg: "File imported");
    }
  }

  void _copyCode(WidgetRef ref) {
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active != null) {
      Clipboard.setData(ClipboardData(text: active.content));
      Fluttertoast.showToast(msg: "Copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      ref.read(fileProvider.notifier).triggerRebuild();
      Fluttertoast.showToast(msg: "Pasted code");
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        File file = File('${dir.path}/${active.name}');
        await file.writeAsString(active.content);
        Fluttertoast.showToast(msg: "Saved to ${file.path}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Download failed: $e");
    }
  }

  void _shareCode(WidgetRef ref) {
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active != null) {
      final base64code = base64Encode(utf8.encode(active.content));
      Share.share('Check out my Dart code!\ndartmini://code?data=$base64code');
      final _ = base64code;
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final active = ref.read(fileProvider.notifier).activeFile;
    if (active == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(active.id);
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
