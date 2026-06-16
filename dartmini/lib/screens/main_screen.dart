import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/compiler_preset.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import '../services/compiler_service.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileProvider.notifier).init();
      ref.read(compilerProvider.notifier).init();
    });
  }

  void _runCode() async {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;

    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first,
    );

    final compilerState = ref.read(compilerProvider);
    final stdin = ref.read(stdinProvider);
    final executionNotifier = ref.read(executionProvider.notifier);

    executionNotifier.setRunning(true);
    OutputSheet.show(context);

    CompilerPreset? preset;
    if (!compilerState.useDefaultOneCompiler && compilerState.activePresetId != null) {
      preset = compilerState.presets.firstWhere(
        (p) => p.id == compilerState.activePresetId,
        orElse: () => compilerState.presets.first,
      );
    }

    final result = await CompilerService.executeCode(
      code: activeFile.content,
      stdin: stdin,
      useDefault: compilerState.useDefaultOneCompiler,
      preset: preset,
    );

    executionNotifier.setOutput(
      stdout: result['stdout'] ?? '',
      stderr: result['stderr'] ?? '',
      executionTime: result['executionTime'] ?? '',
      memory: result['memory'] ?? '',
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: const Text('Delete this file? This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted", backgroundColor: Colors.green);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      String name = result.files.single.name;
      ref.read(fileProvider.notifier).importFile(name, content);
      Fluttertoast.showToast(msg: "Imported $name");
    }
  }

  Future<void> _downloadFile() async {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;

    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first,
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${activeFile.name}');
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Saved to Documents: ${activeFile.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving file");
    }
  }

  Future<void> _shareCode() async {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;

    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first,
    );
    await Share.share(activeFile.content, subject: 'DartMini: ${activeFile.name}');
  }

  Future<void> _copyCode() async {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;

    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first,
    );
    await Clipboard.setData(ClipboardData(text: activeFile.content));
    Fluttertoast.showToast(msg: "Code copied to clipboard");
  }

  Future<void> _pasteCode() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
        final content = clipboardData.text!;
        ref.read(fileProvider.notifier).updateActiveFileContent(content);
        Fluttertoast.showToast(msg: "Code pasted from clipboard");
    }
  }

  void _newFile() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'filename.dart',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                if (!name.endsWith('.dart')) name += '.dart';
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

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final isExecutionRunning = ref.watch(executionProvider).isRunning;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF050505),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top AppBar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.black,
                child: Row(
                  children: [
                    const Text(
                      'DartMini',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'beta',
                        style: TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: isExecutionRunning ? null : _runCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            if (isExecutionRunning)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                            const SizedBox(width: 4),
                            const Text(
                              'Run',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // File Tabs
              if (fileState.files.isNotEmpty)
                Container(
                  height: 40,
                  color: const Color(0xFF111111),
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
                            color: isActive ? const Color(0xFF1a1a1a) : Colors.transparent,
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
                              color: isActive ? Colors.white : Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Toolbar
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildToolbarButton('New', Icons.add, _newFile),
                    _buildToolbarButton('Import', Icons.download_rounded, _importFile),
                    _buildToolbarButton('Copy', Icons.copy, _copyCode),
                    _buildToolbarButton('Paste', Icons.paste, _pasteCode),
                    _buildToolbarButton('Download', Icons.save_alt, _downloadFile),
                    _buildToolbarButton('Share', Icons.share, _shareCode),
                    _buildToolbarButton('Delete', Icons.delete_outline, _confirmDelete),
                    _buildToolbarButton('Settings', Icons.settings, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),

              // Stdin input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),

              // Editor
              Expanded(
                child: fileState.files.isEmpty
                    ? const Center(child: Text("No files open", style: TextStyle(color: Colors.white54)))
                    : const EditorWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC), // Cream/white background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
