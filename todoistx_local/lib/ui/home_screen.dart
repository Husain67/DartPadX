import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'editor_widget.dart';
import 'console_sheet.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../services/compiler_service.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CompilerService _compilerService = CompilerService();
  bool _isRunning = false;

  String _formatCode(String code) {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      return formatter.format(code);
    } catch(e) {
      return code;
    }
  }

  void _runCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null || activeFile.content.isEmpty) {
      Fluttertoast.showToast(msg: "No code to run!");
      return;
    }

    setState(() {
      _isRunning = true;
    });

    final preset = ref.read(compilerProvider).activePreset;

    // Auto-open console
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ConsoleSheet(
        isRunning: true,
        result: null,
      ),
    );

    final result = await _compilerService.executeCode(activeFile.content, preset);

    if (!mounted) return;
    setState(() {
      _isRunning = false;
    });

    // Update bottom sheet if it's still open
    Navigator.pop(context); // Close the loading sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConsoleSheet(
        isRunning: false,
        result: result,
      ),
    );
  }

  Widget _buildToolbarButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: AppTheme.toolbarButtonBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  void _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final name = result.files.single.name;
        ref.read(fileProvider.notifier).importFile(name, content);
        Fluttertoast.showToast(msg: "Imported $name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  void _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      // ignore: unused_local_variable
      Directory? d;
      if (Platform.isAndroid) {
        d = await getExternalStorageDirectory();
      } else {
        d = await getApplicationDocumentsDirectory();
      }

      final path = '${d!.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Saved to $path");
    } catch (e) {
      Fluttertoast.showToast(msg: "Download failed: $e");
    }
  }

  void _deleteFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteFile(activeFile.id);
      Fluttertoast.showToast(msg: "File deleted");
    }
  }

  void _handleFormatShortcut() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatted = _formatCode(activeFile.content);
        ref.read(fileProvider.notifier).updateContent(activeFile.id, formatted);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch(e) {
        Fluttertoast.showToast(msg: "Format failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleFormatShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _handleFormatShortcut,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _runCode,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _runCode,
      },
      child: Focus(
        autofocus: true,
        child: Container(
          decoration: AppTheme.gradientBackground,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'beta',
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runCode,
                    icon: _isRunning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Toolbar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildToolbarButton(
                        icon: Icons.add,
                        tooltip: 'New File',
                        onTap: () => ref.read(fileProvider.notifier).createNewFile(),
                      ),
                      _buildToolbarButton(
                        icon: Icons.file_download,
                        tooltip: 'Import .dart',
                        onTap: _importFile,
                      ),
                      _buildToolbarButton(
                        icon: Icons.format_align_left,
                        tooltip: 'Format Code',
                        onTap: _handleFormatShortcut,
                      ),
                      _buildToolbarButton(
                        icon: Icons.copy,
                        tooltip: 'Copy code',
                        onTap: () {
                          final content = ref.read(fileProvider).activeFile?.content ?? '';
                          Clipboard.setData(ClipboardData(text: content));
                          Fluttertoast.showToast(msg: "Copied to clipboard");
                        },
                      ),
                      _buildToolbarButton(
                        icon: Icons.paste,
                        tooltip: 'Paste',
                        onTap: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null && data.text != null) {
                            final active = ref.read(fileProvider).activeFile;
                            if (active != null) {
                              ref.read(fileProvider.notifier).updateContent(active.id, data.text!);
                              Fluttertoast.showToast(msg: "Pasted from clipboard");
                            }
                          }
                        },
                      ),
                      _buildToolbarButton(
                        icon: Icons.save_alt,
                        tooltip: 'Download .dart',
                        onTap: _downloadFile,
                      ),
                      _buildToolbarButton(
                        icon: Icons.share,
                        tooltip: 'Share',
                        onTap: () {
                          final content = ref.read(fileProvider).activeFile?.content ?? '';
                          Share.share(content);
                        },
                      ),
                      _buildToolbarButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete file',
                        onTap: _deleteFile,
                      ),
                      _buildToolbarButton(
                        icon: Icons.settings,
                        tooltip: 'Settings',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ],
                  ),
                ),
                // Editor
                const Expanded(
                  child: EditorWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
