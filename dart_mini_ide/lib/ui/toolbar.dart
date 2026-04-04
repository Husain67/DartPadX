import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'settings_screen.dart';
import 'examples_gallery.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppConstants.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 1)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _ToolbarBtn(
            icon: Icons.note_add_outlined,
            tooltip: 'New File',
            onTap: () => ref.read(fileProvider.notifier).createNewFile(),
          ),
          _ToolbarBtn(
            icon: Icons.download_outlined,
            tooltip: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final content = await file.readAsString();
                final name = result.files.single.name;
                ref.read(fileProvider.notifier).createNewFile(name, content);
                Fluttertoast.showToast(msg: "Imported $name");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.copy_outlined,
            tooltip: 'Copy Code',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.paste_outlined,
            tooltip: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                   ref.read(fileProvider.notifier).updateContent(activeFile.content + data.text!);
                   Fluttertoast.showToast(msg: "Pasted");
                }
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.format_align_left_outlined,
            tooltip: 'Format Code',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                  final formatted = formatter.format(activeFile.content);
                  ref.read(fileProvider.notifier).updateContent(formatted);
                  Fluttertoast.showToast(msg: "Code Formatted");
                } catch (e) {
                  Fluttertoast.showToast(msg: "Syntax error, couldn't format");
                }
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.file_download_outlined,
            tooltip: 'Download .dart',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final directory = await getTemporaryDirectory();
                final file = File('${directory.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                await Share.shareXFiles([XFile(file.path)], text: 'Exported ${activeFile.name}');
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final base64Code = base64Encode(utf8.encode(activeFile.content));
                final link = 'dartmini://share?code=$base64Code';
                Clipboard.setData(ClipboardData(text: link));
                Fluttertoast.showToast(msg: "Deep-link copied to clipboard");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.delete_outline,
            tooltip: 'Delete File',
            iconColor: Colors.redAccent,
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.bgLight,
                    title: const Text('Delete this file?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(fileProvider.notifier).deleteFileById(activeFile.id);
                          Navigator.pop(context);
                          Fluttertoast.showToast(msg: "File deleted");
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.cleaning_services_outlined,
            tooltip: 'Clear Output',
            onTap: () {
               ref.read(executionProvider.notifier).clearOutput();
               Fluttertoast.showToast(msg: "Output cleared");
            },
          ),
          _ToolbarBtn(
            icon: Icons.library_books_outlined,
            tooltip: 'Examples Gallery',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExamplesGallery()),
              );
            },
          ),
          _ToolbarBtn(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
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
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;

  const _ToolbarBtn({

    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = AppTheme.toolbarIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppConstants.toolbarButtonSize,
          height: AppConstants.toolbarButtonSize,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.toolbarBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.toolbarBorder, width: 1),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
