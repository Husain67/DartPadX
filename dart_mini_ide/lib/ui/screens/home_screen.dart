import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(activeFileProvider);
    final files = ref.watch(fileListProvider);
    final isExecuting = ref.watch(isExecutingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("DartMini"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "beta",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Examples',
            onPressed: () {
              _showExamplesDialog(context, ref);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: isExecuting
                  ? null
                  : () {
                      if (activeFile != null) {
                        ref.read(executionProvider).runCode(activeFile.content, "");
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: isExecuting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text("Run"),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // File Tabs
              Container(
                height: 40,
                color: Colors.black,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isActive = file.id == activeFile?.id;
                    return InkWell(
                      onTap: () {
                        ref.read(activeFileIdProvider.notifier).state = file.id;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? AppConstants.primaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  // Ask to delete? Or just close tab?
                                  // For now, close invokes delete confirmation in toolbar usually.
                                  // Here, maybe just switch file if possible, or delete.
                                  // Let's make it delete for now to be consistent with "closable with X" which usually means close/delete in simple editors.
                                  // But if it's persistent storage, maybe just "close view" not delete file?
                                  // But requirement says "Delete current file... Full Working".
                                  // So X here probably means Delete or Close.
                                  // Let's implement Delete here too with dialog.
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete File?'),
                                      content: const Text('This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                             ref.read(fileListProvider.notifier).deleteFile(file.id);
                                             Navigator.pop(ctx);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const EditorToolbar(),
              const Expanded(child: EditorWidget()),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello, World!');\n}",
      'Async/Await': "Future<void> main() async {\n  print('Start');\n  await Future.delayed(Duration(seconds: 1));\n  print('End');\n}",
      'Class & Object': "class Person {\n  String name;\n  Person(this.name);\n  void sayHello() => print('Hello, \$name');\n}\n\nvoid main() {\n  var p = Person('Dart');\n  p.sayHello();\n}",
      'List & Map': "void main() {\n  var list = [1, 2, 3];\n  var map = {'a': 1, 'b': 2};\n  print('List: \$list');\n  print('Map: \$map');\n}",
      'JSON Parsing': "import 'dart:convert';\n\nvoid main() {\n  var jsonString = '{\"name\": \"Dart\", \"age\": 10}';\n  var parsed = jsonDecode(jsonString);\n  print(parsed['name']);\n}",
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Examples Gallery'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: examples.entries.map((e) => ListTile(
              title: Text(e.key),
              onTap: () {
                ref.read(fileListProvider.notifier).createNewFile(
                  name: '${e.key.replaceAll(' ', '_').toLowerCase()}.dart',
                  content: e.value,
                );
                Navigator.pop(ctx);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
