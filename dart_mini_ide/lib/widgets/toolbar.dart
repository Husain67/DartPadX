import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'settings_screen.dart';
import 'examples_gallery.dart';

class AppToolbar extends ConsumerWidget {
  const AppToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(icon: Icons.add, label: 'New File', onTap: () => _newFile(ref)),
          _ToolbarButton(icon: Icons.file_download, label: 'Import .dart', onTap: () => _importFile(ref)),
          _ToolbarButton(icon: Icons.copy, label: 'Copy code', onTap: () => _copyCode(ref)),
          _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: () => _pasteCode(ref)),
          _ToolbarButton(icon: Icons.download, label: 'Download .dart', onTap: () => _downloadFile(ref)),
          _ToolbarButton(icon: Icons.share, label: 'Share', onTap: () => _shareCode(ref)),
          _ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: () => _deleteFile(context, ref)),
          _ToolbarButton(icon: Icons.format_align_left, label: 'Format', onTap: () => _formatCode(ref)),
          _ToolbarButton(icon: Icons.clear_all, label: 'Clear Output', onTap: () => _clearOutput(ref)),
          _ToolbarButton(icon: Icons.book, label: 'Examples', onTap: () => _openExamples(context)),
          _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () => _openSettings(context)),
        ],
      ),
    );
  }

  void _newFile(WidgetRef ref) {
    ref.read(fileProvider.notifier).addFile();
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;
        ref.read(fileProvider.notifier).addFile(name: name, content: content);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file");
    }
  }

  Future<void> _copyCode(WidgetRef ref) async {
    final file = ref.read(fileProvider.notifier).activeFile;
    if (file != null) {
      await Clipboard.setData(ClipboardData(text: file.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      ref.read(fileProvider.notifier).updateContent(data!.text!);
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
     final file = ref.read(fileProvider.notifier).activeFile;
     if (file == null) return;
     try {
       final dir = await getTemporaryDirectory();
       final _ = dir;
       final tempFile = File('\${dir.path}/\${file.name}');
       await tempFile.writeAsString(file.content);
       await Share.shareXFiles([XFile(tempFile.path)], text: 'Download \${file.name}');
     } catch (e) {
       Fluttertoast.showToast(msg: "Error sharing file");
     }
  }

  Future<void> _shareCode(WidgetRef ref) async {
     final file = ref.read(fileProvider.notifier).activeFile;
     if (file == null) return;
     final base64Code = base64Encode(utf8.encode(file.content));
     final _ = base64Code;
     await Clipboard.setData(ClipboardData(text: "dartmini://code?data=$base64Code"));
     Fluttertoast.showToast(msg: "Deep-link copied to clipboard");
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
    final file = ref.read(fileProvider.notifier).activeFile;
    if (file == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Delete "\${file.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteActiveFile();
      Fluttertoast.showToast(msg: "File deleted");
    }
  }

  Future<void> _formatCode(WidgetRef ref) async {
     final file = ref.read(fileProvider.notifier).activeFile;
     if (file == null) return;
     try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formatted = formatter.format(file.content);
        ref.read(fileProvider.notifier).updateContent(formatted);
        Fluttertoast.showToast(msg: "Code formatted");
     } catch (e) {
        Fluttertoast.showToast(msg: "Syntax error, could not format");
     }
  }

  void _clearOutput(WidgetRef ref) {
    ref.read(executionProvider.notifier).clearOutput();
  }

  void _openExamples(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesGallery()));
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
      padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
      child: Material(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
