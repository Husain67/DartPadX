import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'settings_screen.dart';
import '../widgets/output_sheet.dart';

void _showExamplesGallery(BuildContext context, WidgetRef ref) {
  final examples = {
    'Hello World': "void main() {\n  print('Hello World!');\n}",
    'Input/Output': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
    'List': "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var number in numbers) {\n    print('Number: \$number');\n  }\n}",
    'Class': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name and I am \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 30);\n  p.introduce();\n}",
    'Async': "Future<void> fetchData() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data fetched!');\n}\n\nvoid main() async {\n  await fetchData();\n}",
  };

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Examples Gallery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...examples.entries.map((entry) => ListTile(
                  title: Text(entry.key, style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.code, color: Color(0xFFFACC15)),
                  onTap: () {
                    ref.read(fileProvider.notifier).addNewFile(name: '${entry.key.toLowerCase().replaceAll(' ', '_')}.dart', content: entry.value);
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: "Loaded ${entry.key} example");
                  },
                )),
          ],
        ),
      );
    },
  );
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final FocusNode _focusNode = FocusNode();
  String _currentFileId = '';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_currentFileId.isNotEmpty) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onTextChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _formatCode() {
    final code = _codeController.text;
    if (code.isEmpty) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(code);
      if (formatted != code) {
        _codeController.text = formatted;
        Fluttertoast.showToast(msg: "Code formatted");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format");
    }
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
      Fluttertoast.showToast(msg: "File imported");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${activeFile.name}');
    await file.writeAsString(activeFile.content);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported ${activeFile.name}');
  }

  Future<void> _shareCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    await Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
  }

  void _deleteCurrentFile() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${activeFile.name}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "${activeFile.name} deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      final activeFile = next.activeFile;
      if (activeFile != null) {
        if (_currentFileId != activeFile.id) {
          _currentFileId = activeFile.id;
          _codeController.text = activeFile.content;
        } else if (_codeController.text != activeFile.content && !_focusNode.hasFocus) {
          // Only update if it's not focused to avoid cursor jumping while typing
          _codeController.text = activeFile.content;
        }
      }
    });

    final executionState = ref.watch(executionProvider);
    final fileState = ref.watch(fileProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'DartMini',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
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
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: executionState.isRunning
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      ref.read(executionProvider.notifier).executeCode();
                    },
                icon: executionState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow_rounded, color: Colors.black),
                label: Text(executionState.isRunning ? 'Running' : 'Run', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Toolbar
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildToolbarButton(Icons.add, 'New File', () => ref.read(fileProvider.notifier).addNewFile()),
                  _buildToolbarButton(Icons.download_rounded, 'Import .dart', _importFile),
                  _buildToolbarButton(Icons.copy, 'Copy Code', () {
                    Clipboard.setData(ClipboardData(text: _codeController.text));
                    Fluttertoast.showToast(msg: "Code copied");
                  }),
                  _buildToolbarButton(Icons.paste, 'Paste', () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      final currentPos = _codeController.selection.baseOffset;
                      if (currentPos >= 0) {
                         final text = _codeController.text;
                         final newText = text.substring(0, currentPos) + data.text! + text.substring(currentPos);
                         _codeController.text = newText;
                         _codeController.selection = TextSelection.collapsed(offset: currentPos + data.text!.length);
                      } else {
                        _codeController.text += data.text!;
                      }
                    }
                  }),
                  _buildToolbarButton(Icons.format_align_left, 'Format Code', _formatCode),
                  _buildToolbarButton(Icons.file_download, 'Download .dart', _downloadFile),
                  _buildToolbarButton(Icons.share, 'Share', _shareCode),
                  _buildToolbarButton(Icons.book, 'Examples Gallery', () => _showExamplesGallery(context, ref)),
                  _buildToolbarButton(Icons.delete_outline, 'Delete current file', _deleteCurrentFile),
                  _buildToolbarButton(Icons.settings, 'Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),

            // File Tabs
            SizedBox(
              height: 40,
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
                        color: isActive ? const Color(0xFF1A1A1A) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Text(
                            file.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white54,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _deleteCurrentFile,
                              child: const Icon(Icons.close, size: 14, color: Colors.white54),
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
              child: Container(
                padding: const EdgeInsets.only(bottom: 48), // Space for bottom sheet
                child: CodeTheme(
                  data: CodeThemeData(styles: atomOneDarkTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      gutterStyle: const GutterStyle(
                        showLineNumbers: true,
                        textStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomSheet: const OutputSheet(),
      ),
    );
  }
}
