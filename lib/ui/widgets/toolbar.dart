import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../providers/file_provider.dart';
import '../../core/theme.dart';
import '../settings/settings_screen.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  void _newFile(WidgetRef ref, BuildContext context) {
    TextEditingController controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Filename.dart'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).createFile(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      String name = result.files.single.name;
      ref.read(fileProvider.notifier).createFile(name, content: content);
    }
  }

  void _copyCode(WidgetRef ref) {
    final state = ref.read(fileProvider);
    if (state.activeFileId != null) {
      final file = state.files.firstWhere((f) => f.id == state.activeFileId);
      Clipboard.setData(ClipboardData(text: file.content));
      Fluttertoast.showToast(msg: "Copied to clipboard", backgroundColor: AppTheme.surfaceColor);
    }
  }

  void _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data!.text!);
      Fluttertoast.showToast(msg: "Pasted", backgroundColor: AppTheme.surfaceColor);
    }
  }

  void _downloadFile(WidgetRef ref) async {
    final state = ref.read(fileProvider);
    if (state.activeFileId != null) {
      final file = state.files.firstWhere((f) => f.id == state.activeFileId);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${file.name}';
      final newFile = File(path);
      await newFile.writeAsString(file.content);
      Fluttertoast.showToast(msg: "Saved to $path", backgroundColor: AppTheme.surfaceColor);
    }
  }

  void _shareCode(WidgetRef ref) {
    final state = ref.read(fileProvider);
    if (state.activeFileId != null) {
      final file = state.files.firstWhere((f) => f.id == state.activeFileId);
      Share.share(file.content, subject: 'Dart Code: ${file.name}');
    }
  }

  void _deleteFile(WidgetRef ref, BuildContext context) {
    final state = ref.read(fileProvider);
    if (state.activeFileId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete File?'),
          content: const Text('Delete this file? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(state.activeFileId!);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: "File deleted", backgroundColor: AppTheme.surfaceColor);
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
    }
  }

  void _formatCode(WidgetRef ref) {
      Fluttertoast.showToast(msg: "Formatting not supported in pure web/mobile without dart format CLI currently.", backgroundColor: AppTheme.surfaceColor);
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Widget _buildButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.surfaceColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.pureBlack),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildButton(Icons.add, 'New File', () => _newFile(ref, context)),
          _buildButton(Icons.file_download, 'Import .dart', () => _importFile(ref)),
          _buildButton(Icons.copy, 'Copy code', () => _copyCode(ref)),
          _buildButton(Icons.paste, 'Paste code', () => _pasteCode(ref)),
          _buildButton(Icons.download, 'Download .dart', () => _downloadFile(ref)),
          _buildButton(Icons.share, 'Share', () => _shareCode(ref)),
          _buildButton(Icons.format_align_left, 'Format Code', () => _formatCode(ref)),
          _buildButton(Icons.delete, 'Delete current file', () => _deleteFile(ref, context)),
          _buildButton(Icons.settings, 'Settings', () => _openSettings(context)),
        ],
      ),
    );
  }
}
