
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/files_provider.dart';
import '../../data/providers/execution_provider.dart';
import '../../data/services/file_service.dart';

import '../widgets/toolbar_button.dart';
import '../widgets/file_tabs.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _stdinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(AppConstants.appName, style: TextStyle(color: AppTheme.text)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                AppConstants.version,
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer(
              builder: (context, ref, child) {
                final isRunning = ref.watch(executionProvider).isRunning;
                return ElevatedButton.icon(
                  onPressed: isRunning ? null : () {
                    FocusScope.of(context).unfocus();
                    ref.read(executionProvider.notifier).executeCode(ref, _stdinCtrl.text);
                  },
                  icon: isRunning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildToolbar(context, ref),
              const FileTabs(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _stdinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Standard Input (stdin)',
                    isDense: true,
                  ),
                ),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 60.0), // Space for output sheet handle
                  child: CodeEditorWidget(),
                ),
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Material(
                elevation: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const OutputSheet(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      color: AppTheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          ToolbarButton(
            icon: Icons.note_add,
            tooltip: 'New File',
            onTap: () => _showNewFileDialog(context, ref),
          ),
          ToolbarButton(
            icon: Icons.file_download,
            tooltip: 'Import .dart',
            onTap: () async {
              final content = await FileService.importDartFile();
              if (content != null) {
                ref.read(filesProvider.notifier).addFile('imported.dart', content);
                Fluttertoast.showToast(msg: 'File imported');
              }
            },
          ),
          ToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onTap: () {
              final code = ref.read(filesProvider).activeFile?.content ?? '';
              Clipboard.setData(ClipboardData(text: code));
              Fluttertoast.showToast(msg: 'Code copied');
            },
          ),
          ToolbarButton(
            icon: Icons.paste,
            tooltip: 'Paste Code',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                ref.read(filesProvider.notifier).updateActiveFileContent(data.text!);
                Fluttertoast.showToast(msg: 'Code pasted');
              }
            },
          ),
          ToolbarButton(
            icon: Icons.download,
            tooltip: 'Download .dart',
            onTap: () async {
              final file = ref.read(filesProvider).activeFile;
              if (file != null) {
                final path = await FileService.downloadDartFile(file.name, file.content);
                if (path != null) {
                  Fluttertoast.showToast(msg: 'Downloaded to \$path');
                } else {
                  Fluttertoast.showToast(msg: 'Failed to download');
                }
              }
            },
          ),
          ToolbarButton(
            icon: Icons.share,
            tooltip: 'Share',
            onTap: () {
              final file = ref.read(filesProvider).activeFile;
              if (file != null) {
                FileService.shareCode(file.content);
              }
            },
          ),
          ToolbarButton(
            icon: Icons.delete,
            tooltip: 'Delete File',
            onTap: () => _confirmDelete(context, ref),
          ),

          ToolbarButton(
            icon: Icons.list_alt,
            tooltip: 'Examples',
            onTap: () => _showExamples(context, ref),
          ),
          ToolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onTap: () => _formatCode(ref),
          ),
          ToolbarButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }


  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello, World!');\n}",
      'List & Loops': "void main() {\n  List<String> fruits = ['Apple', 'Banana', 'Cherry'];\n  for (var fruit in fruits) {\n    print(fruit);\n  }\n}",
      'Class Example': "class Person {\n  String name;\n  int age;\n  Person(this.name, this.age);\n  void greet() => print('Hi, I am \$name, \$age years old.');\n}\n\nvoid main() {\n  var p = Person('Alice', 25);\n  p.greet();\n}",
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Examples Gallery'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: examples.length,
            itemBuilder: (context, index) {
              String title = examples.keys.elementAt(index);
              String code = examples.values.elementAt(index);
              return ListTile(
                title: Text(title),
                onTap: () {
                  ref.read(filesProvider.notifier).addFile(title.replaceAll(' ', '_').toLowerCase() + '.dart', code);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: 'Example loaded');
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _formatCode(WidgetRef ref) {
    // Basic format via regex/trim since dart_style has dependency issues
    final code = ref.read(filesProvider).activeFile?.content ?? '';
    if (code.isEmpty) return;
    final formatted = code.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // remove multiple empty lines
    ref.read(filesProvider.notifier).updateActiveFileContent(formatted);
    Fluttertoast.showToast(msg: 'Code formatted (basic)');
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New File'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'File Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(filesProvider.notifier).addFile(ctrl.text, '');
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(filesProvider.notifier).deleteActiveFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
