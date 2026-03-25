import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/file_provider.dart';
import '../models/code_file.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolButton(
            icon: Icons.add,
            label: 'New',
            onTap: () => ref.read(fileProvider.notifier).newFile(),
          ),
          _buildToolButton(
            icon: Icons.file_download,
            label: 'Import',
            onTap: () => _importFile(ref),
          ),
          _buildToolButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _copyCode(ref),
          ),
          _buildToolButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          _buildToolButton(
            icon: Icons.auto_fix_high,
            label: 'Format',
            onTap: () => _formatCode(ref),
          ),
          _buildToolButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () => _downloadFile(ref),
          ),
          _buildToolButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          _buildToolButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _deleteFile(context, ref),
            isDanger: true,
          ),
          _buildToolButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.pillDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isDanger ? AppTheme.errorRed : AppTheme.textDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDanger ? AppTheme.errorRed : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final name = result.files.single.name;

      // Creating a temporary ID, if we open it, the provider assigns an ID or uses it.
      // Better to use newFile and rename.
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(fileProvider.notifier).openFile(
            CodeFile(id: newId, name: name, content: content),
          );
      Fluttertoast.showToast(msg: 'File imported successfully');
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        // Appends to bottom for simplicity, or just set it (setting it here)
        final newContent = activeFile.content + '\n' + data!.text!;
        ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
        Fluttertoast.showToast(msg: 'Code pasted');
      }
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Syntax error, could not format');
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final dir = await getTemporaryDirectory();
      final file = File('\${dir.path}/\${activeFile.name}');
      await file.writeAsString(activeFile.content);

      await Share.shareXFiles([XFile(file.path)], text: 'Downloaded \${activeFile.name}');
    }
  }

  Future<void> _shareCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
        title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
