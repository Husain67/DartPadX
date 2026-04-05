import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'dart:io';
import 'package:highlight/languages/dart.dart';
import 'package:dart_style/dart_style.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../providers/file_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';
import 'widgets/toolbar.dart';
import 'widgets/output_sheet.dart';
import 'settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController!.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
  }

  @override
  void dispose() {
    _codeController?.removeListener(_onCodeChanged);
    _codeController?.dispose();
    super.dispose();
  }

  void _runCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final preset = ref.read(settingsProvider.notifier).getActivePreset();
    if (preset == null) {
      Fluttertoast.showToast(msg: 'No compiler preset selected.', backgroundColor: Colors.red);
      return;
    }

    ref.read(executionProvider.notifier).runCode(preset, activeFile.content);
  }

  void _formatCode() {
    final text = _codeController!.text;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(text);
      _codeController!.text = formatted;
      Fluttertoast.showToast(msg: 'Code formatted', backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Format failed', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        if (previous?.activeFileId != null) {
          ref.read(fileProvider.notifier).forceSaveActive();
        }
        if (next.activeFile != null && next.activeFile!.content != _codeController!.text) {
          _codeController!.text = next.activeFile!.content;
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : _runCode,
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                disabledBackgroundColor: const Color(0xFFFACC15).withValues(alpha: 0.5),
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
              // Tabs
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (context, index) {
                    final file = fileState.files[index];
                    final isActive = file.id == fileState.activeFileId;
                    return GestureDetector(
                      onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF1a1a1a) : Colors.black,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showDeleteConfirm(file.id),
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Toolbar
              EditorToolbar(
                onNewFile: () => _showNewFileDialog(),
                onImport: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['dart', 'txt'],
                  );
                  if (result != null && result.files.single.path != null) {
                    File file = File(result.files.single.path!);
                    String content = await file.readAsString();
                    String name = result.files.single.name;
                    ref.read(fileProvider.notifier).createNewFile(name, content);
                    Fluttertoast.showToast(msg: 'File imported', backgroundColor: Colors.green);
                  }
                },
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: _codeController!.text));
                  Fluttertoast.showToast(msg: 'Copied to clipboard');
                },
                onPaste: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null && data.text != null) {
                    _codeController!.text = data.text!;
                    Fluttertoast.showToast(msg: 'Pasted from clipboard');
                  }
                },
                onDownload: () async {
                  final activeFile = ref.read(fileProvider).activeFile;
                  if (activeFile != null) {
                    final directory = await getTemporaryDirectory();
                    final path = '${directory.path}/${activeFile.name}';
                    final file = File(path);
                    await file.writeAsString(_codeController!.text);
                    await Share.shareXFiles([XFile(path)], text: 'Download ${activeFile.name}');
                  }
                },
                onShare: () {
                  final base64code = base64Encode(utf8.encode(_codeController!.text));
                  Share.share('Check out my Dart code: \n\n$base64code');
                },
                onDelete: () {
                  if (fileState.activeFileId != null) {
                    _showDeleteConfirm(fileState.activeFileId!);
                  }
                },
                onSettings: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                onFormat: _formatCode,
              ),
              // Editor
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
                    )
                  ),
                  child: CodeTheme(
                    data: CodeThemeData(styles: monokaiSublimeTheme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: _codeController!,
                        gutterStyle: const GutterStyle(
                          showLineNumbers: true,
                          textStyle: TextStyle(color: Colors.grey),
                        ),
                        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  void _showNewFileDialog() {
    String name = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'filename.dart', hintStyle: TextStyle(color: Colors.grey)),
          onChanged: (v) => name = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (name.isNotEmpty) {
                ref.read(fileProvider.notifier).createNewFile(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
