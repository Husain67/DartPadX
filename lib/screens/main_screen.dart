import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';
import '../models/code_file.dart';
import 'package:uuid/uuid.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _showOutput = false;

  void _runCode() {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile != null) {
      setState(() { _showOutput = true; });
      ref.read(compilerProvider.notifier).executeCode(activeFile.content);
    }
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();

      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: result.files.single.name,
        content: content,
      );
      ref.read(filesProvider.notifier).addFile(newFile);
      Fluttertoast.showToast(msg: "File imported");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${activeFile.name}');
    await file.writeAsString(activeFile.content);

    await Share.shareXFiles([XFile(file.path)], text: 'Download ${activeFile.name}');
  }

  void _shareCode() {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile == null) return;

    final base64Code = base64Encode(utf8.encode(activeFile.content));
    Share.share('Check out my Dart code!\n\nBase64:\n$base64Code');
  }

  void _formatCode() {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile == null) return;

    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(activeFile.content);
      ref.read(filesProvider.notifier).updateContent(activeFile.id, formatted);
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Format error: syntax issue");
    }
  }

  void _showExamplesGallery() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              title: const Text('Hello World'),
              onTap: () {
                ref.read(filesProvider.notifier).createFile("void main() {\n  print('Hello World!');\n}");
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Input / Output'),
              onTap: () {
                ref.read(filesProvider.notifier).createFile("import 'dart:io';\n\nvoid main() {\n  print('Enter something:');\n  String? input = stdin.readLineSync();\n  print('You entered: \$input');\n}");
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('List & Iteration'),
              onTap: () {
                ref.read(filesProvider.notifier).createFile("void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var num in numbers) {\n    print('Number: \$num');\n  }\n}");
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Class Example'),
              onTap: () {
                ref.read(filesProvider.notifier).createFile("class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, \$name');\n}\n\nvoid main() {\n  var p = Person('Alice');\n  p.greet();\n}");
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Async / Await'),
              onTap: () {
                ref.read(filesProvider.notifier).createFile("Future<void> fetchData() async {\n  await Future.delayed(Duration(seconds: 1));\n  print('Data loaded');\n}\n\nvoid main() async {\n  print('Fetching...');\n  await fetchData();\n}");
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCurrentFile() {
    final activeFile = ref.read(filesProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Delete this file? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(filesProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ElevatedButton.icon(
              onPressed: _runCode,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Toolbar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ToolbarButton(
                        icon: Icons.add,
                        label: 'New File',
                        onTap: () => ref.read(filesProvider.notifier).createFile(),
                      ),
                      ToolbarButton(
                        icon: Icons.file_download_outlined,
                        label: 'Import .dart',
                        onTap: _importFile,
                      ),
                      ToolbarButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () async {
                          final f = ref.read(filesProvider).activeFile;
                          if (f != null) {
                            await Clipboard.setData(ClipboardData(text: f.content));
                            Fluttertoast.showToast(msg: "Copied");
                          }
                        },
                      ),
                      ToolbarButton(
                        icon: Icons.paste,
                        label: 'Paste',
                        onTap: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          final f = ref.read(filesProvider).activeFile;
                          if (data?.text != null && f != null) {
                            ref.read(filesProvider.notifier).updateContent(f.id, data!.text!);
                            Fluttertoast.showToast(msg: "Pasted");
                          }
                        },
                      ),
                      ToolbarButton(
                        icon: Icons.download,
                        label: 'Download .dart',
                        onTap: _downloadFile,
                      ),
                      ToolbarButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: _shareCode,
                      ),
                      ToolbarButton(
                        icon: Icons.format_align_left,
                        label: 'Format',
                        onTap: _formatCode,
                      ),
                      ToolbarButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: _deleteCurrentFile,
                      ),
                      ToolbarButton(
                        icon: Icons.library_books,
                        label: 'Examples',
                        onTap: _showExamplesGallery,
                      ),
                      ToolbarButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                // Editor
                const Expanded(child: EditorWidget()),
              ],
            ),

            // Output Sheet Overlay
            if (_showOutput)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.4,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! > 10) {
                      setState(() { _showOutput = false; });
                    }
                  },
                  child: const OutputSheet(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
