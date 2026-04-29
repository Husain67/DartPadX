import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import '../providers/all_providers.dart';
import '../utils/theme.dart';
import '../utils/file_ops.dart';
import 'settings_screen.dart';
import '../widgets/output_sheet.dart';

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
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _runCode() {
    FocusScope.of(context).unfocus();
    ref.read(fileProvider.notifier).forceSave();
    final code = _codeController.text;
    final stdin = _stdinController.text;
    ref.read(executionProvider.notifier).runCode(code, stdin);
  }

  void _formatCode() {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(_codeController.text);
      _codeController.text = formatted;
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Format error: Check syntax");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync controller with state
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        final activeFile = next.files.firstWhere((f) => f.id == next.activeFileId, orElse: () => next.files.first);
        if (_codeController.text != activeFile.content) {
          _codeController.text = activeFile.content;
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('DartMini', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryAccent, borderRadius: BorderRadius.circular(12)),
                          child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: execState.isRunning ? null : _runCode,
                      icon: execState.isRunning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.play_arrow),
                      label: Text(execState.isRunning ? 'Running' : 'Run'),
                    )
                  ],
                ),
              ),

              // Toolbar
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ToolbarBtn(icon: Icons.add, label: 'New File', onTap: () {
                      _showNewFileDialog(context, ref);
                    }),
                    _ToolbarBtn(icon: Icons.file_download, label: 'Import .dart', onTap: () async {
                      final content = await FileOps.importDartFile();
                      if (content != null) {
                         ref.read(fileProvider.notifier).addFile('imported.dart', content);
                      }
                    }),
                    _ToolbarBtn(icon: Icons.copy, label: 'Copy code', onTap: () => FileOps.copyToClipboard(_codeController.text)),
                    _ToolbarBtn(icon: Icons.paste, label: 'Paste', onTap: () async {
                      final text = await FileOps.pasteFromClipboard();
                      if (text != null) {
                        _codeController.text = text;
                        // force state update so UI syncs
                        ref.read(fileProvider.notifier).updateActiveFileContent(text);
                      }
                    }),
                    _ToolbarBtn(icon: Icons.download, label: 'Download .dart', onTap: () {
                      final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);
                      FileOps.downloadDartFile(activeFile.name, _codeController.text);
                    }),
                    _ToolbarBtn(icon: Icons.share, label: 'Share', onTap: () => FileOps.shareCode(_codeController.text)),
                    _ToolbarBtn(icon: Icons.format_align_left, label: 'Format', onTap: _formatCode),
                    _ToolbarBtn(icon: Icons.delete, label: 'Delete', onTap: () {
                      _showDeleteConfirmation(context, ref);
                    }),

                    _ToolbarBtn(icon: Icons.list_alt, label: 'Examples', onTap: () {
                      _showExamplesDialog(context, ref);
                    }),
                    _ToolbarBtn(icon: Icons.settings, label: 'Settings', onTap: () {

                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

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
                      onTap: () {
                        ref.read(fileProvider.notifier).forceSave();
                        ref.read(fileProvider.notifier).setActiveFile(file.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white10 : Colors.transparent,
                          border: Border(bottom: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 2)),
                        ),
                        child: Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.white54)),
                      ),
                    );
                  },
                ),
              ),

              // Editor & Stdin
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.keyR, control: true): _runCode,
                    const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => ref.read(fileProvider.notifier).forceSave(),
                    const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true): _formatCode,
                  },
                  child: Focus(
                    autofocus: true,
                    child: Stack(
                      children: [
                        Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: CodeTheme(
                              data: CodeThemeData(styles: draculaTheme),
                              child: CodeField(
                                controller: _codeController,
                                gutterStyle: const GutterStyle(showLineNumbers: true, textStyle: TextStyle(color: Colors.white54)),
                                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _stdinController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Standard Input (stdin)',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white10,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // Space for bottom sheet handle
                      ],
                    ),
                    const OutputSheet(),
                  ],
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

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Filename (e.g. hello.dart)', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(fileProvider.notifier).addFile(ctrl.text, '');
              }
              Navigator.pop(context);
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'List & Loops': "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var n in numbers) {\n    print(n);\n  }\n}",
      'Class & Object': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, \$name!');\n}\n\nvoid main() {\n  var p = Person('Dart');\n  p.greet();\n}",
      'Async/Await': "Future<void> main() async {\n  print('Fetching...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}",
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Examples', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: examples.length,
            itemBuilder: (context, index) {
              final key = examples.keys.elementAt(index);
              final value = examples.values.elementAt(index);
              return ListTile(
                title: Text(key, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile("\${key.replaceAll(' ', '_')}.dart", value);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Fluttertoast.showToast(msg: "File deleted");
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.toolbarBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.toolbarBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
