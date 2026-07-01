import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/theme.dart';
import '../models/file_model.dart';
import '../providers/file_provider.dart';

class ExampleItem {
  final String title;
  final String description;
  final String code;

  ExampleItem(this.title, this.description, this.code);
}

final List<ExampleItem> dartExamples = [
  ExampleItem(
    'Hello World',
    'A simple print statement.',
    "void main() {\n  print('Hello, World!');\n}",
  ),
  ExampleItem(
    'Input / Output',
    'Read from stdin and print to stdout.',
    "import 'dart:io';\n\nvoid main() {\n  print('Enter something:');\n  String? input = stdin.readLineSync();\n  print('You entered: $input');\n}",
  ),
  ExampleItem(
    'List Operations',
    'Creating, mapping, and filtering lists.',
    "void main() {\n  var numbers = [1, 2, 3, 4, 5];\n  var doubled = numbers.map((n) => n * 2).toList();\n  print('Original: $numbers');\n  print('Doubled: $doubled');\n}",
  ),
  ExampleItem(
    'Classes & Objects',
    'A basic Dart class definition.',
    "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void greet() {\n    print('Hi, I am $name, $age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 28);\n  p.greet();\n}",
  ),
  ExampleItem(
    'Async / Await',
    'Simulating network requests with Futures.',
    "Future<String> fetchData() async {\n  await Future.delayed(Duration(seconds: 1));\n  return 'Data loaded!';\n}\n\nvoid main() async {\n  print('Fetching...');\n  String result = await fetchData();\n  print(result);\n}",
  ),
];

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTheme.gradientBackground(
      Scaffold(
        appBar: AppBar(title: const Text('Examples Gallery')),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dartExamples.length,
          itemBuilder: (context, index) {
            final ex = dartExamples[index];
            return Card(
              color: Colors.black45,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                subtitle: Text(ex.description, style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  onPressed: () {
                    final newFile = FileModel(
                      id: const Uuid().v4(),
                      name: '${ex.title.replaceAll(' ', '_').toLowerCase()}.dart',
                      content: ex.code,
                    );
                    ref.read(fileProvider.notifier).addOrOpenFile(newFile);
                    Fluttertoast.showToast(msg: 'Loaded ${ex.title}');
                    Navigator.pop(context);
                  },
                  child: const Text('Load'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
