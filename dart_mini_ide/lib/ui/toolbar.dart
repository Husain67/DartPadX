import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPillButton(Icons.add, 'New File', () => _newFile(context, ref)),
          _buildPillButton(Icons.file_download, 'Import .dart', () => _importFile(context, ref)),
          _buildPillButton(Icons.copy, 'Copy', () => _copyCode(ref)),
          _buildPillButton(Icons.paste, 'Paste', () => _pasteCode(ref)),
          _buildPillButton(Icons.download, 'Download .dart', () => _downloadFile(ref)),
          _buildPillButton(Icons.share, 'Share', () => _shareCode(ref)),
          _buildPillButton(Icons.format_align_left, 'Format', () => _formatCode(ref)),
          _buildPillButton(Icons.delete, 'Delete', () => _deleteFile(context, ref), isDestructive: true),
          _buildPillButton(Icons.settings, 'Settings', () => _openSettings(context)),
          _buildPillButton(Icons.library_books, 'Examples', () => _openExamples(context)),
        ],
      ),
    );
  }

  Widget _buildPillButton(IconData icon, String tooltip, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppTheme.toolbarButtonBg,
          shape: const StadiumBorder(side: BorderSide(color: AppTheme.toolbarButtonBorder, width: 1)),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? AppTheme.errorRed : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Filename'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).createNewFile(title: controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;
        ref.read(fileProvider.notifier).createNewFile(title: name, content: content);
        Fluttertoast.showToast(msg: "Imported $name", backgroundColor: AppTheme.successGreen);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e", backgroundColor: AppTheme.errorRed);
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Copied to clipboard", backgroundColor: AppTheme.successGreen);
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null) {
        ref.read(fileProvider.notifier).updateActiveContent(data!.text!, triggerStateUpdate: true);
        Fluttertoast.showToast(msg: "Pasted from clipboard", backgroundColor: AppTheme.successGreen);
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${activeFile.title}');
      await file.writeAsString(activeFile.content);
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final encoded = base64Encode(utf8.encode(activeFile.content));
      Share.share('Check out my Dart code on DartMini IDE:\ndartmini://code?c=$encoded');
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final formatted = ref.read(executionProvider.notifier).formatCode(activeFile.content);
      ref.read(fileProvider.notifier).updateActiveContent(formatted, triggerStateUpdate: true);
      Fluttertoast.showToast(msg: "Code formatted", backgroundColor: AppTheme.successGreen);
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted", backgroundColor: AppTheme.successGreen);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _openExamples(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
  }
}
