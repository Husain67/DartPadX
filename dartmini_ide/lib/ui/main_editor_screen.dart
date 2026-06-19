import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import '../services/execution_service.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import 'editor_widget.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';

class MainEditorScreen extends ConsumerStatefulWidget {
  const MainEditorScreen({super.key});

  @override
  ConsumerState<MainEditorScreen> createState() => _MainEditorScreenState();
}

class _MainEditorScreenState extends ConsumerState<MainEditorScreen> {
  final TextEditingController _stdinController = TextEditingController();

  Future<void> _runCode() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) {
      Fluttertoast.showToast(msg: "No active file");
      return;
    }

    final compilerState = ref.read(compilerProvider);
    final activePreset = ref.read(compilerProvider.notifier).activePreset;

    if (compilerState.useDefaultOneCompiler) {
      final defaultPreset = compilerState.presets.firstWhere(
        (p) => p.name == 'OneCompiler' && p.isBuiltIn,
        orElse: () => throw Exception("OneCompiler not found"),
      );

      const apiKey = String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: '');
      final keyToUse = apiKey.isNotEmpty ? apiKey : AppConstants.defaultOneCompilerKey;

      final modifiedHeaders = Map<String, String>.from(defaultPreset.headers);
      if (modifiedHeaders['X-RapidAPI-Key'] == '{api_key}') {
         modifiedHeaders['X-RapidAPI-Key'] = keyToUse;
      }

      final presetToRun = defaultPreset.copyWith(headers: modifiedHeaders);
      _executeWithPreset(activeFile.content, presetToRun);
    } else {
      if (activePreset == null) {
        Fluttertoast.showToast(msg: "No custom preset selected");
        return;
      }
      _executeWithPreset(activeFile.content, activePreset);
    }
  }

  Future<void> _executeWithPreset(String code, CompilerPreset preset) async {
    ref.read(executionProvider.notifier).startExecution();

    final result = await ExecutionService.executeCode(
      code: code,
      stdin: _stdinController.text,
      preset: preset,
    );

    ref.read(executionProvider.notifier).finishExecution(
      output: result.output,
      error: result.error,
      time: result.time,
      memory: result.memory,
    );
  }

  void _showStdinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Input (stdin)', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _stdinController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: 'Enter standard input here...',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppTheme.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!, width: 1),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNewFile() async {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'filename.dart'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newFile = CodeFile(
                  name: name.endsWith('.dart') ? name : '\$name.dart',
                  content: '// New Dart file\nvoid main() {\n  \n}\n',
                );
                ref.read(fileProvider.notifier).addFile(newFile);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;

        final newFile = CodeFile(name: name, content: content);
        ref.read(fileProvider.notifier).addFile(newFile);
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: \$e");
    }
  }

  Future<void> _handleCopy() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      await Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _handlePaste() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final newContent = activeFile.content + data.text!;
        ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
        Fluttertoast.showToast(msg: "Pasted from clipboard");
      }
    }
  }

  Future<void> _handleDownload() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('\${dir.path}/\${activeFile.name}');
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to \${file.path}");
      } catch (e) {
        Fluttertoast.showToast(msg: "Download failed");
      }
    }
  }

  Future<void> _handleShare() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      await Share.share(activeFile.content, subject: 'Shared from DartMini IDE');
    }
  }

  Future<void> _handleDelete() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _formatCode() {
    // A simplified format approach (just notify toast for now, format is done via analyzer usually or simple indentation rules)
    // flutter_code_editor supports auto-indenting on typing.
    Fluttertoast.showToast(msg: "Format code triggered");
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
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
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_outlined, color: Colors.grey),
            onPressed: _showStdinDialog,
            tooltip: 'Input (stdin)',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isExecuting ? null : _runCode,
              icon: execState.isExecuting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Stack(
          children: [
            Column(
              children: [
                // Toolbar
                SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    children: [
                      _buildToolbarButton(Icons.add, 'New File', _handleNewFile),
                      _buildToolbarButton(Icons.download, 'Import', _handleImport),
                      _buildToolbarButton(Icons.copy, 'Copy', _handleCopy),
                      _buildToolbarButton(Icons.paste, 'Paste', _handlePaste),
                      _buildToolbarButton(Icons.save_alt, 'Download', _handleDownload),
                      _buildToolbarButton(Icons.share, 'Share', _handleShare),
                      _buildToolbarButton(Icons.format_align_left, 'Format', _formatCode),
                      _buildToolbarButton(Icons.delete, 'Delete', _handleDelete),
                      _buildToolbarButton(Icons.settings, 'Settings', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      }),
                    ],
                  ),
                ),
                // Editor Area
                const Expanded(child: EditorWidget()),
              ],
            ),
            // Output Sheet
            const OutputSheet(),
          ],
        ),
      ),
    );
  }
}
