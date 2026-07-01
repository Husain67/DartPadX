import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_style/dart_style.dart';

import '../../core/theme.dart';
import '../../providers/file_provider.dart';
import '../../models/file_model.dart';
import '../settings_screen.dart';
import '../examples_screen.dart';

class MainToolbar extends ConsumerWidget {
  const MainToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
            },
          ),
          _buildToolButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () => _importFile(ref),
          ),
          _buildToolButton(
            icon: Icons.lightbulb_outline,
            label: 'Examples',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
            },
          ),
          _buildToolButton(
            icon: Icons.format_align_left,
            label: 'Format Code',
            onTap: () => _formatCode(ref),
          ),
          _buildToolButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _copyCode(ref),
          ),
          _buildToolButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          _buildToolButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onTap: () => _downloadFile(ref),
          ),
          _buildToolButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          _buildToolButton(
            icon: Icons.delete_outline,
            label: 'Delete file',
            onTap: () => _deleteFile(context, ref),
          ),
          _buildToolButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: AppTheme.toolbarButtonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.toolbarButtonBorder, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

  FileModel? _getActiveFile(WidgetRef ref) {
    final state = ref.read(fileProvider);
    if (state.activeFileId == null) return null;
    try {
      return state.openFiles.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = utf8.decode(result.files.single.bytes!);
        String name = result.files.single.name;
        final newFile = FileModel(
          id: const Uuid().v4(),
          name: name,
          content: content,
        );
        ref.read(fileProvider.notifier).addOrOpenFile(newFile);
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  Future<void> _formatCode(WidgetRef ref) async {
    final file = _getActiveFile(ref);
    if (file != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formattedCode = formatter.format(file.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Format failed (check syntax)");
      }
    }
  }

  Future<void> _copyCode(WidgetRef ref) async {
    final file = _getActiveFile(ref);
    if (file != null) {
      await Clipboard.setData(ClipboardData(text: file.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final file = _getActiveFile(ref);
    if (file != null) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(file.content + '\n' + data.text!);
        Fluttertoast.showToast(msg: "Pasted from clipboard");
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final file = _getActiveFile(ref);
    if (file == null) return;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final path = '${directory.path}/${file.name}';
        final f = File(path);
        await f.writeAsString(file.content);
        Fluttertoast.showToast(msg: "Saved to $path");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Download failed: $e");
    }
  }

  Future<void> _shareCode(WidgetRef ref) async {
    final file = _getActiveFile(ref);
    if (file != null) {
      await Share.share(file.content, subject: 'Dart Code: ${file.name}');
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
    final file = _getActiveFile(ref);
    if (file == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete ${file.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteActiveFile();
      Fluttertoast.showToast(msg: "File deleted");
    }
  }
}
