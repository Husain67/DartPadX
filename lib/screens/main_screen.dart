import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import '../services/compiler_service.dart';
import '../widgets/toolbar.dart';
import 'examples_screen.dart';
import '../widgets/output_console.dart';
import 'settings_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  Timer? _saveTimer;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEditor();
    });
  }

  void _initEditor() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      _currentFileId = activeFile.id;
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _codeController!.addListener(_onCodeChanged);
      setState(() {});
    }
  }

  void _onCodeChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_codeController != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _codeController?.removeListener(_onCodeChanged);
    _codeController?.dispose();
    super.dispose();
  }

  void _syncEditor() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && activeFile.id != _currentFileId) {
      _currentFileId = activeFile.id;
      _codeController?.removeListener(_onCodeChanged);
      _codeController?.dispose();
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _codeController!.addListener(_onCodeChanged);
      setState(() {});
    }
  }

  void _handleNewFile() {
    showDialog(
      context: context,
      builder: (context) {
        String fileName = 'untitled.dart';
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'File Name'),
            onChanged: (val) => fileName = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (!fileName.endsWith('.dart')) fileName += '.dart';
                ref.read(fileProvider.notifier).addFile(fileName, '');
                Navigator.pop(context);
                _syncEditor();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
              _syncEditor();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleRun() async {
    if (_codeController == null) return;

    ref.read(executionProvider.notifier).setExecuting(true);

    final code = _codeController!.text;
    final stdin = ref.read(stdinProvider);

    final compilerState = ref.read(compilerProvider);
    var preset = ref.read(compilerProvider.notifier).activePreset;

    if (compilerState.useDefaultOneCompiler || preset == null) {
      preset = compilerState.presets.firstWhere((p) => p.id == 'onecompiler_default', orElse: () => compilerState.presets.first);
    }

    final result = await CompilerService.execute(
      preset: preset,
      code: code,
      stdin: stdin,
    );

    ref.read(executionProvider.notifier).setResult(
      stdout: result.stdout,
      stderr: result.stderr,
      error: result.error,
      executionTime: result.executionTime,
      memory: result.memory,
    );
  }

  void _formatCode() {
    if (_codeController == null) return;
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(_codeController!.text);
      _codeController!.text = formatted;
      Fluttertoast.showToast(msg: 'Code formatted');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Syntax error, cannot format code');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        _syncEditor();
      }
    });

    final fileState = ref.watch(fileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_align_left, color: Colors.white),
            tooltip: 'Format Code',
            onPressed: _formatCode,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              onPressed: _handleRun,
              icon: ref.watch(executionProvider).isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Toolbar(

                onNewFile: _handleNewFile,
                onImport: () async {
                  // Show modal for Example Gallery vs Local File
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Import Code'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.code),
                            title: const Text('From Examples Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.folder),
                            title: const Text('From Local File'),
                            onTap: () async {
                              Navigator.pop(context);
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['dart', 'txt'],
                              );
                              if (result != null && result.files.single.path != null) {
                                final file = File(result.files.single.path!);
                                final fileContent = await file.readAsString();
                                ref.read(fileProvider.notifier).addFile(result.files.single.name, fileContent);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onCopy: () {
                  if (_codeController != null) {
                    Clipboard.setData(ClipboardData(text: _codeController!.text));
                    Fluttertoast.showToast(msg: 'Code copied to clipboard');
                  }
                },
                onPaste: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data != null && data.text != null && _codeController != null) {
                    final newText = _codeController!.text + data.text!;
                    _codeController!.text = newText;
                  }
                },
                onDownload: () async {
                  if (_codeController == null) return;
                  try {
                    final directory = await getApplicationDocumentsDirectory();
                    final activeFile = ref.read(fileProvider.notifier).activeFile;
                    final fileName = activeFile?.name ?? 'code.dart';
                    final file = File('${directory.path}/$fileName');
                    await file.writeAsString(_codeController!.text);
                    Fluttertoast.showToast(msg: 'Saved to ${file.path}');
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Error downloading file');
                  }
                },
                onShare: () {
                  if (_codeController != null) {
                    final base64Code = base64Encode(utf8.encode(_codeController!.text));
                    Share.share('Check out my Dart code on DartMini IDE!\n\ndartmini://code?data=$base64Code');
                  }
                },
                onDelete: _handleDelete,
                onSettings: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
              // Tabs
              Container(
                height: 40,
                color: const Color(0xFF1E1E1E),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (context, index) {
                    final file = fileState.files[index];
                    final isActive = file.id == fileState.activeFileId;
                    return GestureDetector(
                      onTap: () {
                        // Force save before switching
                        if (_codeController != null) {
                          ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
                        }
                        ref.read(fileProvider.notifier).setActiveFile(file.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF2D2D2D) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          file.name,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Stdin input field for API code execution
              Container(
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    icon: Icon(Icons.input, size: 16, color: Colors.grey),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  onChanged: (val) {
                    ref.read(stdinProvider.notifier).state = val;
                  },
                ),
              ),
              // Editor
              Expanded(
                child: _codeController == null
                    ? const Center(child: CircularProgressIndicator())
                    : CodeTheme(
                        data: CodeThemeData(styles: monokaiSublimeTheme),
                        child: SingleChildScrollView(
                          child: CodeField(
                            controller: _codeController!,
                            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                            gutterStyle: const GutterStyle(
                              textStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              showLineNumbers: true,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 100), // padding for output console
            ],
          ),
          const OutputConsole(),
        ],
      ),
    );
  }
}
