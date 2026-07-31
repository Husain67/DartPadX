import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/code_file.dart';
import '../../data/providers/app_state.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> _examples = const [
    {
      'title': 'Hello World',
      'code': 'void main() {\n  print("Hello, World!");\n}'
    },
    {
      'title': 'List Operations',
      'code': 'void main() {\n  var numbers = [1, 2, 3, 4, 5];\n  var doubled = numbers.map((n) => n * 2).toList();\n  print(doubled);\n}'
    },
    {
      'title': 'Simple Class',
      'code': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("DartMini");\n  p.greet();\n}'
    },
    {
      'title': 'Async / Await',
      'code': 'Future<void> fetch() async {\n  print("Fetching...");\n  await Future.delayed(Duration(seconds: 1));\n  print("Done!");\n}\n\nvoid main() async {\n  await fetch();\n}'
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Examples Gallery'),
        backgroundColor: AppTheme.appBarColor,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _examples.length,
          itemBuilder: (context, index) {
            final ex = _examples[index];
            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(ex['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent),
                  onPressed: () {
                    final newFile = CodeFile(
                      id: uuid.v4(),
                      name: '\${ex['title']!.replaceAll(' ', '_').toLowerCase()}.dart',
                      content: ex['code']!,
                    );
                    ref.read(editorProvider.notifier).addFile(newFile);
                    Navigator.pop(context); // Go back to editor
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
