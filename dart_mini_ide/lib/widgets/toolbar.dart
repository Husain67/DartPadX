import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_style/dart_style.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import '../screens/settings.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundStart,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildBtn(icon: Icons.add, label: 'New', onTap: () => _newFile(context, ref)),
          _buildBtn(icon: Icons.download, label: 'Import', onTap: () => _importFile(ref)),
          _buildBtn(icon: Icons.copy, label: 'Copy', onTap: () => _copyCode(fileState.activeFile?.content ?? '')),
          _buildBtn(icon: Icons.paste, label: 'Paste', onTap: () => _pasteCode(ref)),
          _buildBtn(icon: Icons.save_alt, label: 'Download', onTap: () => _downloadFile(fileState.activeFile)),
          _buildBtn(icon: Icons.share, label: 'Share', onTap: () => _shareCode(fileState.activeFile?.content ?? '')),
          _buildBtn(icon: Icons.delete, label: 'Delete', onTap: () => _deleteFile(context, ref, fileState.activeFile?.id)),
          _buildBtn(icon: Icons.format_align_left, label: 'Format', onTap: () => _formatCode(ref)),
          _buildBtn(icon: Icons.settings, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _buildBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.toolbarBg,
            border: Border.all(color: AppTheme.toolbarBorder),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'filename.dart', hintStyle: TextStyle(color: Colors.grey))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim().isEmpty ? 'untitled.dart' : ctrl.text.trim();
              ref.read(fileProvider.notifier).createFile(name.endsWith('.dart') ? name : '$name.dart');
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['dart', 'txt']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      ref.read(fileProvider.notifier).createFile(result.files.single.name, content: content);
      Fluttertoast.showToast(msg: "File imported");
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveContent(data.text!);
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  Future<void> _downloadFile(var activeFile) async {
    if (activeFile == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${activeFile.name}');
      await file.writeAsString(activeFile.content);
      await Share.shareXFiles([XFile(file.path)], subject: 'Download ${activeFile.name}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _shareCode(String code) async {
    final bytes = utf8.encode(code);
    final base64Code = base64Encode(bytes);
    final deepLink = 'https://dartmini.ide/share?code=$base64Code';
    await Share.share('Check out my Dart code!\n\n$deepLink');
  }

  void _deleteFile(BuildContext context, WidgetRef ref, String? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted", backgroundColor: Colors.red);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _formatCode(WidgetRef ref) {
    final state = ref.read(fileProvider);
    final active = state.activeFile;
    if (active != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formatted = formatter.format(active.content);
        ref.read(fileProvider.notifier).updateActiveContent(formatted);
        Fluttertoast.showToast(msg: "Code formatted", backgroundColor: Colors.green);
      } catch (e) {
        Fluttertoast.showToast(msg: "Format failed: Syntax error", backgroundColor: Colors.red);
      }
    }
  }
}
