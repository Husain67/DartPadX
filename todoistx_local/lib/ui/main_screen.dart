import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../providers/file_notifier.dart';
import '../providers/settings_notifier.dart';
import '../services/compiler_service.dart';
import '../theme/app_theme.dart';
import 'widgets/toolbar.dart';
import 'widgets/output_sheet.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  final TextEditingController _stdinController = TextEditingController();
  bool _isRunning = false;
  ExecutionResult? _executionResult;
  String? _executionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEditor();
    });
  }

  void _initEditor() {
    final files = ref.read(filesProvider);
    final activeId = ref.read(activeFileIdProvider);

    if (files.isNotEmpty) {
      if (activeId == null) {
        ref.read(activeFileIdProvider.notifier).state = files.first.id;
      }

      final currentId = ref.read(activeFileIdProvider);
      final activeFile = files.firstWhere((f) => f.id == currentId, orElse: () => files.first);

      _controllerDispose();
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );

      _codeController!.addListener(() {
        final currentId = ref.read(activeFileIdProvider);
        if (currentId != null) {
          ref.read(filesProvider.notifier).updateFileContent(currentId, _codeController!.text);
        }
      });
      setState(() {});
    }
  }

  void _controllerDispose() {
    _codeController?.dispose();
    _codeController = null;
  }

  @override
  void dispose() {
    _controllerDispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _switchFile(String id) {
    ref.read(activeFileIdProvider.notifier).state = id;
    _initEditor();
  }

  Future<void> _runCode() async {
    final files = ref.read(filesProvider);
    final activeId = ref.read(activeFileIdProvider);
    final activeFile = files.firstWhere((f) => f.id == activeId, orElse: () => files.first);

    final settings = ref.read(settingsProvider);
    final stdinInput = _stdinController.text;

    setState(() {
      _isRunning = true;
      _executionResult = null;
      _executionError = null;
    });

    // We store the state setter for the bottom sheet so we can update it in-place
    StateSetter? bottomSheetSetState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          bottomSheetSetState = setSheetState;
          return OutputSheet(
            isRunning: _isRunning,
            result: _executionResult,
            error: _executionError,
          );
        },
      ),
    );

    try {
      ExecutionResult result;
      if (settings.useOneCompiler) {
        result = await CompilerService.executeWithOneCompiler(activeFile.content, stdinInput);
      } else {
        final preset = settings.presets.firstWhere((p) => p.id == settings.activePresetId);
        result = await CompilerService.executeWithPreset(preset, activeFile.content, stdinInput);
      }

      if (mounted) {
        setState(() {
          _executionResult = result;
          _isRunning = false;
        });
        bottomSheetSetState?.call(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _executionError = e.toString();
          _isRunning = false;
        });
        bottomSheetSetState?.call(() {});
      }
    }
  }

  void _newFile() {
    ref.read(filesProvider.notifier).createFile('untitled${ref.read(filesProvider).length}.dart');
    final files = ref.read(filesProvider);
    _switchFile(files.last.id);
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        ref.read(filesProvider.notifier).importFile(result.files.single.name, content);
        final files = ref.read(filesProvider);
        _switchFile(files.last.id);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file: $e");
    }
  }

  void _copyCode() {
    if (_codeController != null) {
      Clipboard.setData(ClipboardData(text: _codeController!.text));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && _codeController != null) {
      final currentSelection = _codeController!.selection;

      String text = _codeController!.text;
      String newText = '';

      if (currentSelection.isValid) {
        newText = text.replaceRange(currentSelection.start, currentSelection.end, data.text!);
        _codeController!.text = newText;
        _codeController!.selection = TextSelection.collapsed(offset: currentSelection.start + data.text!.length);
      } else {
        newText = text + data.text!;
        _codeController!.text = newText;
        _codeController!.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  Future<void> _downloadCode() async {
    final files = ref.read(filesProvider);
    final activeId = ref.read(activeFileIdProvider);
    final activeFile = files.firstWhere((f) => f.id == activeId, orElse: () => files.first);

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        directory = dirs?.first;
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to ${file.path}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to save file: $e");
    }
  }

  void _shareCode() {
    final files = ref.read(filesProvider);
    final activeId = ref.read(activeFileIdProvider);
    final activeFile = files.firstWhere((f) => f.id == activeId, orElse: () => files.first);

    Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
  }

  void _deleteCurrentFile() {
    final files = ref.read(filesProvider);
    if (files.length <= 1) {
      Fluttertoast.showToast(msg: "Cannot delete the last file.");
      return;
    }

    final activeId = ref.read(activeFileIdProvider);
    final activeFile = files.firstWhere((f) => f.id == activeId, orElse: () => files.first);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete File'),
        content: Text('Delete "${activeFile.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(filesProvider.notifier).deleteFile(activeId!);
              final newFiles = ref.read(filesProvider);
              _switchFile(newFiles.first.id);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _formatCode() {
    if (_codeController == null) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(_codeController!.text);
      _codeController!.text = formatted;
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Formatting error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesProvider);
    final activeId = ref.watch(activeFileIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Container(
                height: 56,
                color: AppTheme.appBarColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'DartMini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'beta',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _runCode,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            if (_isRunning)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            else
                              const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                            const SizedBox(width: 4),
                            const Text(
                              'Run',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Toolbar
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    ToolbarButton(icon: Icons.add, label: 'New File', onTap: _newFile),
                    ToolbarButton(icon: Icons.file_download, label: 'Import', onTap: _importFile),
                    ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: _copyCode),
                    ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: _pasteCode),
                    ToolbarButton(icon: Icons.download, label: 'Download', onTap: _downloadCode),
                    ToolbarButton(icon: Icons.share, label: 'Share', onTap: _shareCode),
                    ToolbarButton(icon: Icons.format_align_left, label: 'Format', onTap: _formatCode),
                    ToolbarButton(icon: Icons.delete_outline, label: 'Delete', color: Colors.red, onTap: _deleteCurrentFile),
                    ToolbarButton(icon: Icons.library_books, label: 'Examples', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
                    }),
                    ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),

              // Standard Input Field
              Container(
                color: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _stdinController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                ),
              ),

              // File Tabs
              if (files.isNotEmpty)
                Container(
                  height: 40,
                  color: const Color(0xFF1A1A1A),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isActive = file.id == activeId;
                      return GestureDetector(
                        onTap: () => _switchFile(file.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.surfaceColor : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                file.name,
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
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
                    ? const Center(child: CircularProgressIndicator())
                    : CodeTheme(
                        data: CodeThemeData(styles: darculaTheme),
                        child: SingleChildScrollView(
                          child: CodeField(
                            controller: _codeController!,
                            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                            gutterStyle: const GutterStyle(
                              textStyle: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              showLineNumbers: true,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
