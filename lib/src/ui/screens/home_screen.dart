import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/code_file.dart';
import '../../data/providers/app_state.dart';
import '../../data/services/compiler_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/file_tabs.dart';
import '../widgets/code_editor_view.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CompilerService _compilerService = CompilerService();

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleRun() async {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile == null) return;

    ref.read(editorProvider.notifier).setExecuting(true);
    ref.read(showOutputProvider.notifier).state = true;
    ref.read(outputListProvider.notifier).state = [OutputData(text: 'Running...', type: 'meta')];

    final preset = ref.read(defaultPresetProvider);
    String stdinStr = '';

    final result = await _compilerService.executeCode(
      code: activeFile.content,
      stdin: stdinStr,
      preset: preset,
    );

    if (!mounted) return;

    ref.read(editorProvider.notifier).setExecuting(false);

    List<OutputData> outList = [];
    if (result.error.isNotEmpty) {
      outList.add(OutputData(text: 'ERROR:\n\${result.error}', type: 'error'));
    }
    if (result.stderr.isNotEmpty) {
      outList.add(OutputData(text: 'STDERR:\n\${result.stderr}', type: 'stderr'));
    }
    if (result.stdout.isNotEmpty) {
      outList.add(OutputData(text: 'STDOUT:\n\${result.stdout}', type: 'stdout'));
    }
    if (result.executionTime.isNotEmpty) {
      outList.add(OutputData(text: '\n[Time: \${result.executionTime}]', type: 'meta'));
    }
    if (result.memory.isNotEmpty) {
      outList.add(OutputData(text: '[Memory: \${result.memory}]', type: 'meta'));
    }

    if (outList.isEmpty) {
      outList.add(OutputData(text: 'No output.', type: 'meta'));
    }

    ref.read(outputListProvider.notifier).state = outList;
  }

  void _handleNewFile() {
    ref.read(editorProvider.notifier).newFile();
  }

  void _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = utf8.decode(result.files.single.bytes!);
        String name = result.files.single.name;

        final newFile = CodeFile(
          id: uuid.v4(),
          name: name,
          content: content,
        );
        ref.read(editorProvider.notifier).addFile(newFile);
        _showToast('Imported \$name');
      }
    } catch (e) {
      _showToast('Error importing file');
    }
  }

  void _handleCopy() {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      _showToast('Copied to clipboard');
    }
  }

  void _handlePaste() async {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final newContent = activeFile.content.isEmpty
            ? data.text!
            : activeFile.content + '\n' + data.text!;
        ref.read(editorProvider.notifier).updateActiveFileContent(newContent);
        _showToast('Pasted from clipboard');
      }
    }
  }

  void _handleDownload() async {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final file = File('\${dir.path}/\${activeFile.name}');
        await file.writeAsString(activeFile.content);
        _showToast('Saved to Downloads/\${activeFile.name}');
      } else {
         _showToast('Could not access storage');
      }
    } catch (e) {
      _showToast('Error saving file');
    }
  }

  void _handleShare() {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
    }
  }

  void _handleFormat() {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatted = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(activeFile.content);
        ref.read(editorProvider.notifier).updateActiveFileContent(formatted);
        _showToast('Formatted code');
      } catch (e) {
        _showToast('Syntax error, could not format');
      }
    }
  }

  void _handleDelete() {
    final activeFileId = ref.read(editorProvider).activeFileId;
    if (activeFileId == null) return;

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(editorProvider.notifier).closeFile(activeFileId);
              Navigator.pop(ctx);
              _showToast('File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExecuting = ref.watch(editorProvider).isExecuting;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        onRunPressed: _handleRun,
        isExecuting: isExecuting,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF111111),
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(AppConstants.appName, style: TextStyle(color: AppTheme.primaryAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.white),
              title: const Text('Examples Gallery'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  EditorToolbar(
                    onNewFile: _handleNewFile,
                    onImport: _handleImport,
                    onCopy: _handleCopy,
                    onPaste: _handlePaste,
                    onDownload: _handleDownload,
                    onShare: _handleShare,
                    onDelete: _handleDelete,
                    onFormat: _handleFormat,
                    onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                  const FileTabs(),
                  const Expanded(
                    child: CodeEditorView(),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: OutputSheet(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
