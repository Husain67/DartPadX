import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/file_provider.dart';
import '../../core/theme.dart';
import 'code_editor.dart';
import '../screens/settings_screen.dart';
import '../screens/examples_gallery.dart';

class Toolbar extends ConsumerWidget {
  final GlobalKey<CodeEditorState> editorKey;

  const Toolbar({super.key, required this.editorKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBlack,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildButton(context, Icons.add, "New", () => _newFile(ref)),
          const SizedBox(width: 8),
          _buildButton(context, Icons.file_upload, "Import", () => _importFile(ref)),
          const SizedBox(width: 8),
          _buildButton(context, Icons.collections_bookmark, "Examples", () => _openExamples(context)),
          const SizedBox(width: 8),
          _buildButton(context, Icons.copy, "Copy", () => _copyCode()),
          const SizedBox(width: 8),
          _buildButton(context, Icons.paste, "Paste", () => _pasteCode()),
          const SizedBox(width: 8),
          _buildButton(context, Icons.download, "Download", () => _downloadFile(ref)),
          const SizedBox(width: 8),
          _buildButton(context, Icons.share, "Share", () => _shareFile(ref)),
          const SizedBox(width: 8),
          _buildButton(context, Icons.delete, "Delete", () => _deleteFile(context, ref), isDestructive: true),
          const SizedBox(width: 8),
          _buildButton(context, Icons.settings, "Settings", () => _openSettings(context)),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppTheme.toolbarButtonColor,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black12),
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppTheme.errorRed : Colors.black87,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _newFile(WidgetRef ref) {
    ref.read(fileProvider.notifier).createNewFile();
    Fluttertoast.showToast(msg: "New file created");
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart'],
      );

      if (result != null) {
        final file = result.files.single;
        if (file.path != null) {
          final content = await File(file.path!).readAsString();
          ref.read(fileProvider.notifier).importFile(file.name, content);
          Fluttertoast.showToast(msg: "File imported");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file: $e");
    }
  }

  Future<void> _copyCode() async {
    final code = editorKey.currentState?.currentCode;
    if (code != null) {
      await Clipboard.setData(ClipboardData(text: code));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      editorKey.currentState?.insertText(data!.text!);
      Fluttertoast.showToast(msg: "Pasted");
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final file = ref.read(fileProvider).activeFile;
    if (file != null) {
      try {
        final dir = await getTemporaryDirectory();
        final tempFile = File('${dir.path}/${file.name}');
        await tempFile.writeAsString(file.content);
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Download ${file.name}');
      } catch (e) {
         Fluttertoast.showToast(msg: "Error downloading: $e");
      }
    }
  }

  Future<void> _shareFile(WidgetRef ref) async {
    final file = ref.read(fileProvider).activeFile;
    if (file != null) {
       Share.share(file.content, subject: file.name);
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete File?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(fileProvider.notifier).deleteActiveFile();
      Fluttertoast.showToast(msg: "File deleted");
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _openExamples(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamplesGallery()),
    );
  }
}
