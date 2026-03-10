import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../screens/settings_screen.dart';
import '../utils/constants.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            label: 'New',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
              Fluttertoast.showToast(msg: "New file created");
            },
          ),
          _buildToolbarButton(
            icon: Icons.download_rounded, // Assuming import arrow down
            label: 'Import',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );
              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String contents = await file.readAsString();
                ref.read(fileProvider.notifier).importFile(result.files.single.name, contents);
                Fluttertoast.showToast(msg: "File imported");
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Code copied to clipboard");
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                  // Simply replaces everything or appends? Let's replace for simplicity
                  // But usually users want to paste at cursor. We'll handle full replace here,
                  // or append. We append to end for now if using toolbar paste.
                  String newContent = activeFile.content + "\\n" + data.text!;
                  ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
                  Fluttertoast.showToast(msg: "Pasted from clipboard");
                }
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.download_done_rounded,
            label: 'Download',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('\${directory.path}/\${activeFile.name}');
                await file.writeAsString(activeFile.content);
                await Share.shareXFiles([XFile(file.path)], text: 'Download \${activeFile.name}');
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                Share.share(activeFile.content, subject: 'Dart snippet: \${activeFile.name}');
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formatter = DartFormatter();
                  final formattedCode = formatter.format(activeFile.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
                  Fluttertoast.showToast(msg: "Code formatted");
                } catch (e) {
                  Fluttertoast.showToast(msg: "Syntax error, cannot format");
                }
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            iconColor: Colors.red,
            onTap: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 showDialog(
                   context: context,
                   builder: (BuildContext context) {
                     return AlertDialog(
                       backgroundColor: AppTheme.backgroundEnd,
                       title: const Text("Delete this file?", style: TextStyle(color: Colors.white)),
                       content: const Text("This cannot be undone.", style: TextStyle(color: Colors.white70)),
                       actions: [
                         TextButton(
                           child: const Text("Cancel", style: TextStyle(color: AppTheme.primaryAccent)),
                           onPressed: () => Navigator.of(context).pop(),
                         ),
                         TextButton(
                           child: const Text("Delete", style: TextStyle(color: Colors.red)),
                           onPressed: () {
                             ref.read(fileProvider.notifier).deleteFileById(activeFile.id);
                             Navigator.of(context).pop();
                             Fluttertoast.showToast(msg: "File deleted");
                           },
                         ),
                       ],
                     );
                   },
                 );
               }
            },
          ),
          _buildToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const SettingsScreen()),
               );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppTheme.toolbarButtonBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.toolbarButtonBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor ?? Colors.black87),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
