import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/files_provider.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  Widget _buildButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.whiteCream,
              border: Border.all(color: AppTheme.borderGray, width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: AppTheme.accentYellow,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(filesProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildButton(Icons.add_box, 'New File', () {
            ref.read(filesProvider.notifier).addFile('untitled.dart');
          }),
          _buildButton(Icons.file_download, 'Import .dart', () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['dart', 'txt'],
            );
            if (result != null && result.files.single.path != null) {
              final file = File(result.files.single.path!);
              final content = await file.readAsString();
              ref.read(filesProvider.notifier).addFile(result.files.single.name, content);
              _showToast('Imported ${result.files.single.name}');
            }
          }),
          _buildButton(Icons.copy, 'Copy code', () {
            if (filesState.activeFileId.isNotEmpty) {
              final activeFile = filesState.files.firstWhere((f) => f.id == filesState.activeFileId);
              Clipboard.setData(ClipboardData(text: activeFile.content));
              _showToast('Code copied');
            }
          }),
          _buildButton(Icons.paste, 'Paste', () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null && filesState.activeFileId.isNotEmpty) {
              final activeFile = filesState.files.firstWhere((f) => f.id == filesState.activeFileId);
              final newContent = activeFile.content + (data.text ?? '');
              ref.read(filesProvider.notifier).updateActiveFileContent(newContent);
              // Force state update to sync cursor
              ref.read(filesProvider.notifier).setActiveFile(activeFile.id);
              _showToast('Code pasted');
            }
          }),
          _buildButton(Icons.download, 'Download .dart', () async {
             if (filesState.activeFileId.isNotEmpty) {
              final activeFile = filesState.files.firstWhere((f) => f.id == filesState.activeFileId);
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/${activeFile.name}');
              await file.writeAsString(activeFile.content);
              _showToast('Saved to ${file.path}');
            }
          }),
          _buildButton(Icons.share, 'Share', () {
            if (filesState.activeFileId.isNotEmpty) {
              final activeFile = filesState.files.firstWhere((f) => f.id == filesState.activeFileId);
              final encoded = base64Encode(utf8.encode(activeFile.content));
              Share.share('Check out my Dart code:\n\ndartmini://code?c=$encoded');
            }
          }),
          _buildButton(Icons.delete, 'Delete', () {
             if (filesState.activeFileId.isEmpty) return;

             showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this file?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                         ref.read(filesProvider.notifier).deleteFile(filesState.activeFileId);
                         Navigator.pop(context);
                         _showToast('File deleted');
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
             );
          }),
          _buildButton(Icons.format_align_left, 'Format', () {
             if (filesState.activeFileId.isNotEmpty) {
              final activeFile = filesState.files.firstWhere((f) => f.id == filesState.activeFileId);
              try {
                final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                final formatted = formatter.format(activeFile.content);
                ref.read(filesProvider.notifier).updateActiveFileContent(formatted);
                ref.read(filesProvider.notifier).setActiveFile(activeFile.id);
                _showToast('Code formatted');
              } catch (e) {
                _showToast('Format error: syntax issue');
              }
            }
          }),
          _buildButton(Icons.settings, 'Settings', () {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }),
        ],
      ),
    );
  }
}
