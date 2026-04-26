import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'editor_widget.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';
import 'examples_gallery.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: InkWell(
              onTap: execState.isRunning
                  ? null
                  : () {
                      ref.read(executionProvider.notifier).runCode();
                    },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: execState.isRunning ? Colors.grey : const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: execState.isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.black, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Run',
                            style: TextStyle(
                                color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(context, ref),
                const Expanded(
                  child: EditorWidget(),
                ),
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _ToolbarBtn(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).newFile();
            },
          ),
          _ToolbarBtn(
            icon: Icons.file_upload,
            label: 'Import',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final content = await file.readAsString();
                ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.download,
            label: 'Download',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                Fluttertoast.showToast(msg: "Downloaded to ${file.path}");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                  final formatted = formatter.format(activeFile.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                  Fluttertoast.showToast(msg: "Code Formatted");
                } catch(e) {
                  Fluttertoast.showToast(msg: "Formatting error (Syntax)");
                }
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.copy,

          label: 'Copy',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                await Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
                Fluttertoast.showToast(msg: "Pasted from clipboard");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final base64Str = base64Encode(utf8.encode(activeFile.content));
                Clipboard.setData(ClipboardData(text: "dartmini://code?b64=$base64Str"));
                Fluttertoast.showToast(msg: "Mock Deep-Link Copied!");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _showDeleteConfirm(context, ref),
          ),
          _ToolbarBtn(
            icon: Icons.collections_bookmark,
            label: 'Examples',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ExamplesGallery()));
            },
          ),
          _ToolbarBtn(
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

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              final activeId = ref.read(fileProvider).activeFileId;
              if (activeId.isNotEmpty) {
                ref.read(fileProvider.notifier).deleteFileById(activeId);
                Fluttertoast.showToast(msg: "File deleted");
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
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
}
