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

import '../providers/providers.dart';
import '../screens/settings_screen.dart';
import 'code_editor_widget.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildButton(Icons.add, 'New File', () => _newFile(context, ref)),
          _buildButton(Icons.file_download, 'Import', () => _importFile(ref)),
          _buildButton(Icons.copy, 'Copy', () => _copyCode(ref)),
          _buildButton(Icons.paste, 'Paste', () => _pasteCode(ref)),
          _buildButton(Icons.download, 'Download', () => _downloadFile(ref)),
          _buildButton(Icons.share, 'Share', () => _shareCode(ref)),
          _buildButton(Icons.delete, 'Delete', () => _deleteFile(context, ref)),
          _buildButton(Icons.format_align_left, 'Format', () => _formatCode(ref)),
          _buildButton(Icons.settings, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF0F0F0),
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.grey, width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  String _getActiveContent(WidgetRef ref) {
    final state = ref.read(fileProvider);
    if (state.activeFileId == null) return '';
    return state.files.firstWhere((f) => f.id == state.activeFileId).content;
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    int count = ref.read(fileProvider).files.length + 1;
    ref.read(fileProvider.notifier).addFile('untitled_$count.dart', '');
  }

  Future<void> _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final name = result.files.single.name;
      final content = utf8.decode(result.files.single.bytes!);
      ref.read(fileProvider.notifier).addFile(name, content);
    }
  }

  void _copyCode(WidgetRef ref) {
    final content = _getActiveContent(ref);
    Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(msg: 'Code copied to clipboard');
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final pasteText = data.text!;
      final state = editorKey.currentState;
      if (state != null && state.controller != null) {
         final ctrl = state.controller!;
         final oldText = ctrl.text;
         final offset = ctrl.selection.baseOffset;
         if (offset >= 0 && offset <= oldText.length) {
            final newText = oldText.substring(0, offset) + pasteText + oldText.substring(offset);
            ref.read(fileProvider.notifier).updateActiveFileContent(newText);
            Fluttertoast.showToast(msg: 'Pasted successfully');
            return;
         }
      }

      // Fallback
      final content = _getActiveContent(ref);
      ref.read(fileProvider.notifier).updateActiveFileContent(content + pasteText);
      Fluttertoast.showToast(msg: 'Pasted successfully');
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final state = ref.read(fileProvider);
    if (state.activeFileId == null) return;

    final file = state.files.firstWhere((f) => f.id == state.activeFileId);

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = '${dir.path}/${file.name}';
        final localFile = File(path);
        await localFile.writeAsString(file.content);
        Fluttertoast.showToast(msg: 'Saved to $path');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error saving file: $e');
    }
  }

  void _shareCode(WidgetRef ref) {
    final content = _getActiveContent(ref);
    if (content.isNotEmpty) {
      Share.share(content);
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final state = ref.read(fileProvider);
    if (state.activeFileId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Delete this file? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(state.activeFileId!);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _formatCode(WidgetRef ref) {
    final content = _getActiveContent(ref);
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(content);
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      Fluttertoast.showToast(msg: 'Code formatted');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Format Error: Syntax error in code');
    }
  }
}
