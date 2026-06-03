import 'dart:convert';
// ignore_for_file: prefer_const_constructors
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../providers.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final TextEditingController _stdinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    _codeController.addListener(() {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null && _codeController.text != activeFile.content) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCodeController();
    });
  }

  void _syncCodeController() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && _codeController.text != activeFile.content) {
      _codeController.text = activeFile.content;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _formatCode() {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formattedCode = formatter.format(_codeController.text);
      _codeController.text = formattedCode;
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format");
    }
  }

  void _showNewFileDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('New File'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'filename.dart'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                String name = nameController.text;
                if (!name.endsWith('.dart')) name += '.dart';
                ref.read(fileProvider.notifier).addFile(name, '');
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncCodeController());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
        ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncCodeController());
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Saved to $path");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving file");
    }
  }

  void _confirmDelete() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
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
              WidgetsBinding.instance.addPostFrameCallback((_) => _syncCodeController());
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  void _showExamples() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Examples'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Hello World'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('hello.dart', "void main() {\n  print('Hello World!');\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Input/Output'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('io.dart', "import 'dart:io';\n\nvoid main() {\n  print('Enter name:');\n  String? name = stdin.readLineSync();\n  print('Hello \$name');\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('List'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('list.dart', "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var n in numbers) {\n    print(n * 2);\n  }\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Class'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('class.dart', "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, I am \$name');\n}\n\nvoid main() {\n  var p = Person('Dart');\n  p.greet();\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Async'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('async.dart', "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Data loaded!');\n}");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runCode() {

    final code = _codeController.text;
    final stdin = _stdinController.text;
    final compilerState = ref.read(compilerProvider);
    ref.read(executionProvider.notifier).executeCode(code, stdin, compilerState);
    _showOutputSheet();
  }

  void _showOutputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OutputSheet(),
    );
  }

  Widget _buildToolbarButton(String tooltip, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    ref.listen(fileProvider.select((state) => state.activeFileId), (prev, next) {
      if (prev != next) {
        _syncCodeController();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: execState.isExecuting ? null : _runCode,
              icon: execState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                _buildToolbarButton('New File', 'New File', _showNewFileDialog),
                _buildToolbarButton('Import', '📥 Import', _importFile),
                _buildToolbarButton('Copy', '📋 Copy', () {
                  Clipboard.setData(ClipboardData(text: _codeController.text));
                  Fluttertoast.showToast(msg: "Copied to clipboard");
                }),
                _buildToolbarButton('Paste', '📝 Paste', () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null && data.text != null) {
                    _codeController.text = data.text!;
                  }
                }),
                _buildToolbarButton('Format', '✨ Format', _formatCode),
                _buildToolbarButton('Download', '⬇️ Download', _downloadFile),
                _buildToolbarButton('Share', '🔗 Share', () {
                  final encoded = base64Encode(utf8.encode(_codeController.text));
                  Share.share('https://dartmini.ide/?code=$encoded');
                }),
                _buildToolbarButton('Delete', '🗑️ Delete', _confirmDelete),
                _buildToolbarButton('Settings', '⚙️ Settings', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _buildToolbarButton('Examples', '📚 Examples', _showExamples),
              ],
            ),
          ),

          // Tabs
          Container(
            height: 40,
            color: const Color(0xFF1A1A1A),
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
                      color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
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
                        Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (fileState.files.length > 1) {
                                ref.read(fileProvider.notifier).deleteFile(file.id);
                            } else {
                               Fluttertoast.showToast(msg: "Cannot close last file");
                            }
                          },
                          child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.grey),
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
              width: double.infinity,
              color: const Color(0xFF1E1E1E), // Editor bg
              child: CodeTheme(
                data: CodeThemeData(styles: monokaiSublimeTheme),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: const GutterStyle(
                       textStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stdin input field at bottom before Output sheet
          Container(
             padding: const EdgeInsets.all(8),
             color: const Color(0xFF1A1A1A),
             child: TextField(
               controller: _stdinController,
               decoration: const InputDecoration(
                 hintText: 'Standard Input (stdin)',
                 isDense: true,
               ),
               style: const TextStyle(color: Colors.white, fontSize: 12),
               maxLines: 1,
               onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
             ),
          ),
        ],
      ),
    );
  }
}

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (state.executionTime.isNotEmpty)
                          Text('Time: ${state.executionTime}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        if (state.memory.isNotEmpty)
                          Text('Mem: ${state.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Color(0xFF333333)),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.isExecuting)
                       const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                    else if (state.stdout.isEmpty && state.stderr.isEmpty)
                       const Text('Ready', style: TextStyle(color: Colors.grey))
                    else ...[
                       if (state.stdout.isNotEmpty)
                         Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                       if (state.stderr.isNotEmpty)
                         Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                    ]
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
