import 'dart:io';
import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';
import 'package:dart_mini_ide/ui/screens/settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0A0A0A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildButton(context, Icons.note_add_outlined, 'New', () => _showNewFileDialog(context, ref)),
            _buildButton(context, Icons.file_upload_outlined, 'Import', () => _importFile(context, ref)),
            const SizedBox(width: 8),
            if (activeFile != null) ...[
              _buildButton(context, Icons.copy_rounded, 'Copy', () => _copyCode(context, activeFile.content)),
              _buildButton(context, Icons.content_paste_rounded, 'Paste', () => _pasteCode(context, ref)),
              _buildButton(context, Icons.download_rounded, 'Download', () => _downloadFile(context, activeFile)),
              _buildButton(context, Icons.share_rounded, 'Share', () => _shareCode(context, activeFile)),
              _buildButton(context, Icons.delete_outline_rounded, 'Delete', () => _confirmDelete(context, ref), isDestructive: true),
            ],
            const SizedBox(width: 8),
            _buildButton(context, Icons.settings_outlined, 'Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: AppColors.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.toolbarButtonBorder, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black87),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'File Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(fileProvider.notifier).createFile(name, "// $name created\nvoid main() {\n  print('Hello World');\n}");
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "File created");
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final content = String.fromCharCodes(file.bytes!); // Assuming UTF-8
      ref.read(fileProvider.notifier).createFile(file.name, content);
      Fluttertoast.showToast(msg: "Imported ${file.name}");
    }
  }

  Future<void> _copyCode(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(msg: "Code copied to clipboard");
  }

  Future<void> _pasteCode(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      // Append or replace? Usually paste inserts at cursor.
      // Since we don't have easy cursor access here (controller is in Editor),
      // we might append or just show a warning.
      // But user expects paste.
      // Simplest: Append to end or Replace All? Replace All is destructive.
      // Maybe insert at end.
      // But `CodeEditor` handles text. `Toolbar` is separate.
      // We can update content via provider.
      // Let's prompt: "Paste at end?" or just append.
      // Actually, better to let `CodeEditor` handle paste via its own UI or keyboard.
      // But button is requested.
      // I'll append to end for now as safe default.
      final currentContent = ref.read(fileProvider).activeFile?.content ?? "";
      final newContent = currentContent + "\n" + data!.text!;
      ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
      Fluttertoast.showToast(msg: "Pasted at end of file");
    }
  }

  Future<void> _downloadFile(BuildContext context, dynamic file) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/${file.name}');
      await tempFile.writeAsString(file.content);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Here is my code: ${file.name}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Error downloading: $e");
    }
  }

  Future<void> _shareCode(BuildContext context, dynamic file) async {
    await Share.share(file.content, subject: file.name);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(fileProvider.notifier).deleteActiveFile();
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
