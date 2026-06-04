import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import '../providers/file_provider.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      color: Colors.transparent,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildToolbarBtn(Icons.add_box_outlined, 'New File', () => _createNewFile(ref, context)),
          _buildToolbarBtn(Icons.file_download_outlined, 'Import', () => _importFile(ref)),
          _buildToolbarBtn(Icons.copy_outlined, 'Copy', () => _copyCode(ref)),
          _buildToolbarBtn(Icons.paste_outlined, 'Paste', () => _pasteCode(ref)),
          _buildToolbarBtn(Icons.download_outlined, 'Download', () => _downloadFile(ref)),
          _buildToolbarBtn(Icons.share_outlined, 'Share', () => _shareCode(ref)),
          _buildToolbarBtn(Icons.delete_outline, 'Delete', () => _deleteFile(ref, context), isDanger: true),
          _buildToolbarBtn(Icons.settings_outlined, 'Settings', () => _openSettings(context)),
        ],
      ),
    );
  }

  Widget _buildToolbarBtn(IconData icon, String tooltip, VoidCallback onTap, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(
              icon,
              color: isDanger ? Colors.red : Colors.black87,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _createNewFile(WidgetRef ref, BuildContext context) {
    TextEditingController ctrl = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
             hintText: 'File name',
             hintStyle: TextStyle(color: Colors.grey),
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () {
            ref.read(fileProvider.notifier).createFile(name: ctrl.text);
            Navigator.pop(ctx);
          }, child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15)))),
        ],
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;
        ref.read(fileProvider.notifier).createFile(name: name, content: content);
        Fluttertoast.showToast(msg: "Imported $name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        // Append or replace? Simple append for now or replace if empty
        String newContent = activeFile.content + data.text!;
        if (activeFile.content.isEmpty) newContent = data.text!;
        ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
        Fluttertoast.showToast(msg: "Pasted from clipboard");
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) dir = await getExternalStorageDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        final filePath = '${dir!.path}/${activeFile.name}';
        final file = File(filePath);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to $filePath");
      } catch (e) {
        Fluttertoast.showToast(msg: "Download failed: $e");
      }
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
    }
  }

  void _deleteFile(WidgetRef ref, BuildContext context) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${activeFile.name}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}
