import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  CodeController? _codeController;
  String? _currentControllerFileId;
  bool _isFormatting = false;

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  void _initController(CodeFile file) {
    _codeController?.dispose();
    _codeController = CodeController(
      text: file.content,
      language: dart,
    );
    _codeController!.addListener(_onCodeChanged);
    _currentControllerFileId = file.id;
  }

  void _onCodeChanged() {
    if (_isFormatting) return;
    if (_codeController != null && _currentControllerFileId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
    }
  }

  void _syncControllerWithState() {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      _codeController?.dispose();
      _codeController = null;
      _currentControllerFileId = null;
      return;
    }

    if (_currentControllerFileId != activeFile.id) {
      _initController(activeFile);
    } else if (_codeController != null && _codeController!.text != activeFile.content) {
      // Content updated from outside (e.g. format)
      _isFormatting = true;
      _codeController!.text = activeFile.content;
      _isFormatting = false;
    }
  }

  void _runCode() {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final settings = ref.read(settingsProvider);

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Show output sheet automatically
    _showOutputSheet(context);

    ref.read(executionProvider.notifier).executeCode(
      code: activeFile.content,
      useOneCompiler: settings.useOneCompiler,
      customPreset: settings.activePreset,
    );
  }

  void _showOutputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OutputSheet(),
    );
  }

  void _formatCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(activeFile.content);
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Format failed: Syntax error");
    }
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = utf8.decode(result.files.single.bytes!);
        String name = result.files.single.name;

        final newFile = CodeFile(name: name, content: content);
        ref.read(fileProvider.notifier).addFile(newFile);
        Fluttertoast.showToast(msg: "Imported \$name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = "\${dir.path}/\${activeFile.name}";
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to \$path");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to download");
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    Share.share(activeFile.content, subject: 'Dart code: \${activeFile.name}');
  }

  void _copyCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    Clipboard.setData(ClipboardData(text: activeFile.content));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  Future<void> _pasteCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      if (_codeController != null) {
         // simplistic append or replace. Ideally insert at cursor.
         final newText = _codeController!.text + data.text!;
         ref.read(fileProvider.notifier).updateActiveFileContent(newText);
         Fluttertoast.showToast(msg: "Pasted");
      }
    }
  }

  void _deleteCurrentFile() {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFile == null) return;

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewFile() {
    final file = CodeFile(name: 'untitled.dart', content: '');
    ref.read(fileProvider.notifier).addFile(file);
  }

  @override
  Widget build(BuildContext context) {
    _syncControllerWithState();
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton(
              onPressed: execState.isRunning ? null : _runCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: execState.isRunning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 4),
                        Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Column(
          children: [
            // Toolbar
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _ToolbarButton(icon: Icons.add, label: 'New', onTap: _createNewFile),
                  _ToolbarButton(icon: Icons.book, label: 'Examples', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()))),
                  _ToolbarButton(icon: Icons.download, label: 'Import', onTap: _importFile),
                  _ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: _copyCode),
                  _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: _pasteCode),
                  _ToolbarButton(icon: Icons.format_align_left, label: 'Format', onTap: _formatCode),
                  _ToolbarButton(icon: Icons.save_alt, label: 'Download', onTap: _downloadFile),
                  _ToolbarButton(icon: Icons.share, label: 'Share', onTap: _shareCode),
                  _ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: _deleteCurrentFile, isDestructive: true),
                  _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),

            // Tabs
            Container(
              height: 40,
              color: AppTheme.backgroundBottom,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fileState.files.length,
                itemBuilder: (context, index) {
                  final file = fileState.files[index];
                  final isActive = file.id == fileState.activeFileId;
                  return GestureDetector(
                    onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.backgroundTop : AppTheme.backgroundBottom,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 14, color: isActive ? AppTheme.primaryAccent : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            file.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _deleteCurrentFile,
                              child: const Icon(Icons.close, size: 14, color: Colors.grey),
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Editor
            Expanded(
              child: _codeController == null
                  ? const Center(child: Text('No file open'))
                  : CodeTheme(
                      data: CodeThemeData(styles: darculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController!,
                          gutterStyle: GutterStyle(
                            textStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            width: 48,
                            margin: 8,
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.toolbarButtonBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.toolbarButtonBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isDestructive ? Colors.red : Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.black87,
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

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundBottom,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty)
                          Text('\${execState.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clear(),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: execState.isRunning
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (execState.stdout.isNotEmpty)
                            Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                          if (execState.stderr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                            ),
                          if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                            const Text('No output', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
