import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../providers/file_provider.dart';
import '../theme.dart';
import '../settings_screen.dart';
import 'dialogs.dart';

class ToolbarView extends ConsumerWidget {
  final CodeController codeController;

  const ToolbarView({super.key, required this.codeController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarBtn(
            icon: Icons.add,
            label: 'New File',
            onTap: () async {
              final name = await showNewFileDialog(context);
              if (name != null && name.isNotEmpty) {
                ref.read(fileProvider.notifier).addFile(name);
              }
            },
          ),
          _buildToolbarBtn(
            icon: Icons.file_upload,
            label: 'Import',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
                withData: true,
              );
              if (result != null) {
                final file = result.files.first;
                final content = utf8.decode(file.bytes!);
                ref.read(fileProvider.notifier).addFile(file.name, content: content);
                Fluttertoast.showToast(msg: "Imported \${file.name}");
              }
            },
          ),
          _buildToolbarBtn(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: codeController.text));
              Fluttertoast.showToast(msg: "Copied to clipboard");
            },
          ),
          _buildToolbarBtn(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                final text = data!.text!;
                final selection = codeController.selection;

                if (selection.isValid) {
                  final newText = codeController.text.replaceRange(
                    selection.start,
                    selection.end,
                    text,
                  );
                  codeController.text = newText;
                  codeController.selection = TextSelection.collapsed(
                    offset: selection.start + text.length,
                  );
                } else {
                  codeController.text += text;
                }
                Fluttertoast.showToast(msg: "Pasted");
              }
            },
          ),
          _buildToolbarBtn(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              try {
                final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
                final formatted = formatter.format(codeController.text);
                codeController.text = formatted;
                Fluttertoast.showToast(msg: "Code Formatted");
              } catch (e) {
                Fluttertoast.showToast(msg: "Format Error: Syntax invalid");
              }
            },
          ),
          _buildToolbarBtn(
            icon: Icons.file_download,
            label: 'Download',
            onTap: () async {
              try {
                final state = ref.read(fileProvider);
                if (state.activeFileId != null) {
                  final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);

                  String? outputFile = await FilePicker.platform.saveFile(
                    dialogTitle: 'Save File',
                    fileName: activeFile.name,
                  );

                  if (outputFile != null) {
                     File file = File(outputFile);
                     await file.writeAsString(codeController.text);
                     Fluttertoast.showToast(msg: "Downloaded successfully");
                  }
                }
              } catch (e) {
                Fluttertoast.showToast(msg: "Error downloading file");
              }
            },
          ),
          _buildToolbarBtn(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              Share.share(codeController.text);
            },
          ),
          _buildToolbarBtn(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () async {
              final state = ref.read(fileProvider);
              if (state.activeFileId != null) {
                final confirm = await showDeleteConfirmationDialog(context);
                if (confirm) {
                  ref.read(fileProvider.notifier).deleteFile(state.activeFileId!);
                  Fluttertoast.showToast(msg: "File deleted");
                }
              }
            },
          ),
          _buildToolbarBtn(
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

  Widget _buildToolbarBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.buttonBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
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
