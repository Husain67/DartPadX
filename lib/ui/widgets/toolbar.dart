import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../data/providers/file_provider.dart';
import '../settings/settings_screen.dart';

class IDEToolbar extends ConsumerWidget {
  const IDEToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildButton(
            icon: Icons.note_add_outlined,
            label: 'New',
            onTap: () => ref.read(fileProvider.notifier).createNewFile(),
          ),
          _buildButton(
            icon: Icons.file_download_outlined,
            label: 'Import',
            onTap: () => _importFile(ref),
          ),
          _buildButton(
            icon: Icons.copy_outlined,
            label: 'Copy',
            onTap: () => _copyCode(ref),
          ),
          _buildButton(
            icon: Icons.paste_outlined,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          _buildButton(
            icon: Icons.format_align_left_outlined,
            label: 'Format',
            onTap: () => _formatCode(ref),
          ),
          _buildButton(
            icon: Icons.download_outlined,
            label: 'Save',
            onTap: () => _downloadFile(ref),
          ),
          _buildButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          _buildButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.redAccent,
            onTap: () => _deleteFile(context, ref),
          ),
          _buildButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.withAlpha(50), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color ?? Colors.black87),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.black87,
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

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        final content = file.bytes != null ? utf8.decode(file.bytes!) : '';
        ref.read(fileProvider.notifier).importFile(file.name, content);
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: \$e");
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: "Code pasted");
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Format failed (syntax error?)");
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectories(
                type: StorageDirectory.downloads))
            ?.first;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final file = File('\${dir.path}/\${activeFile.name}');
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to \${file.path}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Save failed: \$e");
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content,
          subject: 'DartMini Code: \${activeFile.name}');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
