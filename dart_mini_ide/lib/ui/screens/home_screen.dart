import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../models/code_file.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CodeController _codeController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      language: dart,
      text: '',
    );

    _codeController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final activeId = ref.read(activeFileIdProvider);
    if (activeId == null) return;

    // Auto-save every 2 seconds
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(filesProvider.notifier).updateFile(activeId, _codeController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _forceSave([String? explicitId]) {
    final activeId = explicitId ?? ref.read(activeFileIdProvider);
    if (activeId != null && _debounceTimer?.isActive == true) {
      _debounceTimer!.cancel();
      ref.read(filesProvider.notifier).updateFile(activeId, _codeController.text);
    }
  }

  void _createNewFile() {
    _forceSave();
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: 'untitled.dart',
      content: '// New Dart File\nvoid main() {\n  \n}',
    );
    ref.read(filesProvider.notifier).addFile(newFile);
    ref.read(activeFileIdProvider.notifier).setActive(newFile.id);
  }

  Future<void> _importFile() async {
    _forceSave();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;

        final newFile = CodeFile(
          id: const Uuid().v4(),
          name: name,
          content: content,
        );

        ref.read(filesProvider.notifier).addFile(newFile);
        ref.read(activeFileIdProvider.notifier).setActive(newFile.id);
        Fluttertoast.showToast(msg: "File imported successfully", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file", backgroundColor: Colors.red);
    }
  }

  Future<void> _downloadFile() async {
    _forceSave();
    final activeId = ref.read(activeFileIdProvider);
    if (activeId == null) return;
    final file = ref.read(filesProvider).firstWhere((f) => f.id == activeId);

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.name}');
      await tempFile.writeAsString(file.content);

      await Share.shareXFiles([XFile(tempFile.path)], text: 'Download ${file.name}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Error downloading file", backgroundColor: Colors.red);
    }
  }

  void _shareFile() {
    _forceSave();
    final activeId = ref.read(activeFileIdProvider);
    if (activeId == null) return;
    final file = ref.read(filesProvider).firstWhere((f) => f.id == activeId);
    Share.share(file.content, subject: 'Shared from DartMini IDE: ${file.name}');
  }

  Future<void> _deleteFile() async {
    final activeId = ref.read(activeFileIdProvider);
    if (activeId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _debounceTimer?.cancel();
      final files = ref.read(filesProvider);
      ref.read(filesProvider.notifier).deleteFile(activeId);

      if (files.length > 1) {
        final nextFile = files.firstWhere((f) => f.id != activeId);
        ref.read(activeFileIdProvider.notifier).setActive(nextFile.id);
      } else {
        _createNewFile();
      }
      Fluttertoast.showToast(msg: "File deleted");
    }
  }

  void _formatCode() {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formattedCode = formatter.format(_codeController.text);
      _codeController.text = formattedCode;
      _forceSave();
      Fluttertoast.showToast(msg: "Code formatted", backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format", backgroundColor: Colors.red);
    }
  }

  void _showExamplesGallery() {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'List Example': "void main() {\n  final list = [1, 2, 3];\n  for (var n in list) {\n    print(n);\n  }\n}",
      'Class Example': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, I am \$name');\n}\n\nvoid main() {\n  Person('Jules').greet();\n}",
      'Async Example': "Future<void> main() async {\n  print('Fetching...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}"
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: examples.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              onTap: () {
                _forceSave();
                final newFile = CodeFile(
                  id: const Uuid().v4(),
                  name: "${e.key.replaceAll(' ', '_').toLowerCase()}.dart",
                  content: e.value,
                );
                ref.read(filesProvider.notifier).addFile(newFile);
                ref.read(activeFileIdProvider.notifier).setActive(newFile.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Example loaded");
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active file changes to sync editor
    ref.listen<String?>(activeFileIdProvider, (previous, next) {
      if (next != null && previous != next) {
        if (previous != null) {
          _forceSave(previous);
        }
        final files = ref.read(filesProvider);
        final file = files.firstWhere((f) => f.id == next, orElse: () => files.first);
        if (file.content != _codeController.text) {
          _codeController.text = file.content;
        }
      }
    });

    final isExecuting = ref.watch(executionProvider).isExecuting;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
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
            icon: const Icon(Icons.library_books, color: Colors.white54),
            tooltip: 'Examples Gallery',
            onPressed: _showExamplesGallery,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: isExecuting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Color(0xFFFACC15), strokeWidth: 3),
                    ),
                  ),
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.black, size: 20),
                        SizedBox(width: 4),
                        Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  onPressed: () {
                    _forceSave();
                    ref.read(executionProvider.notifier).executeCode(_codeController.text);
                  },
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
              ),
            ),
            child: Column(
              children: [
                ToolbarWidget(
                  onNewFile: _createNewFile,
                  onImport: _importFile,
                  onCopy: () async {
                    await Clipboard.setData(ClipboardData(text: _codeController.text));
                    Fluttertoast.showToast(msg: "Copied to clipboard");
                  },
                  onPaste: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _codeController.text = data!.text!;
                      _forceSave();
                      Fluttertoast.showToast(msg: "Pasted from clipboard");
                    }
                  },
                  onDownload: _downloadFile,
                  onShare: _shareFile,
                  onDelete: _deleteFile,
                  onFormat: _formatCode,
                  onSettings: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                Expanded(
                  child: EditorWidget(controller: _codeController),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: OutputSheet(),
          ),
        ],
      ),
    );
  }
}
