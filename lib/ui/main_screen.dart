import 'package:flutter/material.dart';
// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_notifier.dart';
import '../providers/execution_notifier.dart';
import 'settings_screen.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _controller;
  String _lastActiveId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
    });
  }

  void _initController() {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;

    final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);

    _controller = CodeController(
      text: activeFile.content,
      language: dart,
    );

    _controller!.addListener(() {
      final currentId = ref.read(fileProvider).activeFileId;
      if (currentId != null && currentId == _lastActiveId) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
      }
    });

    _lastActiveId = activeFile.id;
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncController() {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null || _controller == null) return;

    if (_lastActiveId != fileState.activeFileId) {
      final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);
      _lastActiveId = activeFile.id;
      _controller!.text = activeFile.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider.select((s) => s.activeFileId), (prev, next) {
      if (prev != next) {
        _syncController();
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    if (_controller == null || fileState.activeFileId == null) {
      return const Scaffold(backgroundColor: Color(0xFF050505), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: execState.isExecuting ? null : _runCode,
              icon: execState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          _buildFileTabs(fileState),
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: CodeField(
                        controller: _controller!,
                        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        gutterStyle: const GutterStyle(
                          textStyle: TextStyle(color: Colors.white54, height: 1.5),
                          margin: 8.0,
                        ),
                      ),
                    ),
                  ),
                ),
                if (execState.stdout.isNotEmpty || execState.stderr.isNotEmpty || execState.isExecuting)
                  OutputSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _toolbarBtn('New File', Icons.insert_drive_file, () => ref.read(fileProvider.notifier).createNewFile()),
          _toolbarBtn('📥 Import', Icons.download, _importFile),
          _toolbarBtn('📋 Copy', Icons.copy, _copyCode),
          _toolbarBtn('📝 Paste', Icons.paste, _pasteCode),
          _toolbarBtn('⬇️ Download', Icons.file_download, _downloadFile),
          _toolbarBtn('🔗 Share', Icons.share, _shareCode),
          _toolbarBtn('🗑️ Delete', Icons.delete, _deleteFile, isDestructive: true),
          _toolbarBtn('⚙️ Settings', Icons.settings, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _toolbarBtn(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFfdfdfd),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black87),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTabs(FileState fileState) {
    return Container(
      height: 40,
      color: Colors.black,
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
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteFileSpecific(file.id, file.name),
                    child: const Icon(Icons.close, size: 16, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _runCode() async {
    final code = _controller!.text;
    final stdin = ref.read(stdinProvider);
    final preset = ref.read(activePresetProvider);

    // Automatically unfocus to hide keyboard before run
    FocusScope.of(context).unfocus();

    ref.read(executionProvider.notifier).executeCode(code, stdin, preset);
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;
        ref.read(fileProvider.notifier).importFile(name, content);
        Fluttertoast.showToast(msg: "Imported $name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _controller!.text));
    Fluttertoast.showToast(msg: "Code copied to clipboard");
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      _controller!.text = data.text!;
      Fluttertoast.showToast(msg: "Pasted code");
    }
  }

  Future<void> _downloadFile() async {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;
    final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to Downloads: ${activeFile.name}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Download failed: $e");
    }
  }

  void _shareCode() {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;
    final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);

    Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
  }

  void _deleteFile() {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;
    final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);
    _deleteFileSpecific(activeFile.id, activeFile.name);
  }

  void _deleteFileSpecific(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: Text('Delete "$name"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
