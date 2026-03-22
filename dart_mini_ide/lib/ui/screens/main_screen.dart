import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import 'dart:async';
import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/files_provider.dart';
import '../../providers/execution_provider.dart';
import '../../utils/theme.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/output_sheet.dart';
import 'compiler_settings_screen.dart';
import 'examples_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  Timer? _debounce;
  String? _currentFileId;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      language: dart,
    );
    _codeController!.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (_currentFileId != null && _codeController != null) {
        ref.read(filesProvider.notifier).updateFileContent(_currentFileId!, _codeController!.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _codeController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _runCode() {
    if (_codeController != null) {
      ref.read(executionProvider.notifier).executeCode(_codeController!.text);
      _sheetController.animateTo(
        0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _formatCode() {
    if (_codeController == null || _currentFileId == null) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(_codeController!.text);
      _codeController!.text = formatted;
      ref.read(filesProvider.notifier).updateFileContent(_currentFileId!, formatted);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format error: $e')));
    }
  }

  void _createNewFile() {
    final id = ref.read(filesProvider.notifier).createFile('untitled.dart', '');
    ref.read(activeFileIdProvider.notifier).state = id;
  }

  void _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final name = result.files.single.name;

      final id = ref.read(filesProvider.notifier).createFile(name, content);
      ref.read(activeFileIdProvider.notifier).state = id;

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $name')));
    }
  }

  void _copyCode() {
    if (_codeController != null) {
      Clipboard.setData(ClipboardData(text: _codeController!.text));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard')));
    }
  }

  void _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && _codeController != null) {
      final currentPos = _codeController!.selection.baseOffset;
      if (currentPos >= 0) {
        final text = _codeController!.text;
        final newText = text.substring(0, currentPos) + data.text! + text.substring(currentPos);
        _codeController!.text = newText;
        _codeController!.selection = TextSelection.collapsed(offset: currentPos + data.text!.length);
      } else {
        _codeController!.text += data.text!;
      }
    }
  }

  void _downloadFile() async {
    if (_currentFileId == null || _codeController == null) return;
    final activeFile = ref.read(filesProvider.notifier).getFile(_currentFileId!);
    if (activeFile == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${activeFile.name}');
    await file.writeAsString(_codeController!.text);

    await Share.shareXFiles([XFile(file.path)], text: 'Downloaded ${activeFile.name}');
  }

  void _shareCode() {
    if (_codeController == null) return;
    Share.share(_codeController!.text, subject: 'Dart Code Snippet');
  }

  void _deleteCurrentFile() {
    if (_currentFileId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final nextId = ref.read(filesProvider.notifier).deleteFile(_currentFileId!);
              ref.read(activeFileIdProvider.notifier).state = nextId;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesProvider);
    final activeFileId = ref.watch(activeFileIdProvider);
    final isRunning = ref.watch(executionProvider).isRunning;

    if (activeFileId != _currentFileId) {
      if (_currentFileId != null && _codeController != null) {
          ref.read(filesProvider.notifier).updateFileContent(_currentFileId!, _codeController!.text);
      }

      _currentFileId = activeFileId;
      final activeFile = ref.read(filesProvider.notifier).getFile(activeFileId!);
      if (activeFile != null) {
        _codeController!.text = activeFile.content;
      } else {
        _codeController!.text = '';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.yellowAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: isRunning ? null : _runCode,
              icon: isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.textDark, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, size: 20),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellowAccent,
                foregroundColor: AppTheme.textDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toolbar
              Container(
                height: 60,
                color: AppTheme.blackBg,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    ToolbarButton(icon: Icons.add_box, label: 'New File', onTap: _createNewFile),
                    ToolbarButton(icon: Icons.library_books, label: 'Examples', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
                    }),
                    ToolbarButton(icon: Icons.download, label: 'Import', onTap: _importFile),
                    ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: _copyCode),
                    ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: _pasteCode),
                    ToolbarButton(icon: Icons.download_for_offline, label: 'Download', onTap: _downloadFile),
                    ToolbarButton(icon: Icons.share, label: 'Share', onTap: _shareCode),
                    ToolbarButton(icon: Icons.format_align_left, label: 'Format', onTap: _formatCode),
                    ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: _deleteCurrentFile),
                    ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CompilerSettingsScreen()));
                    }),
                  ],
                ),
              ),
              // File Tabs
              Container(
                height: 40,
                color: AppTheme.darkBg,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isActive = file.id == activeFileId;
                    return GestureDetector(
                      onTap: () {
                         ref.read(activeFileIdProvider.notifier).state = file.id;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.blackBg : AppTheme.darkBg,
                          border: Border(bottom: BorderSide(color: isActive ? AppTheme.yellowAccent : Colors.transparent, width: 2)),
                        ),
                        child: Row(
                          children: [
                             Text(
                              file.name,
                              style: TextStyle(
                                color: isActive ? AppTheme.yellowAccent : AppTheme.whiteCream,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    final nextId = ref.read(filesProvider.notifier).deleteFile(file.id);
                                    ref.read(activeFileIdProvider.notifier).state = nextId;
                                  },
                                  child: const Icon(Icons.close, size: 16, color: AppTheme.yellowAccent),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Editor
              Expanded(
                child: Container(
                  color: AppTheme.blackBg,
                  child: CodeTheme(
                    data: const CodeThemeData(styles: draculaTheme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: _codeController!,
                        gutterStyle: const GutterStyle(showLineNumbers: true),
                        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Output Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return const OutputSheet();
            },
          ),
        ],
      ),
    );
  }
}
