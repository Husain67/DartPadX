import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ExampleCard(
              title: 'Hello World',
              description: 'The classic starting point.',
              code: "void main() {\n  print('Hello, World!');\n}",
              ref: ref,
              context: context,
            ),
            _ExampleCard(
              title: 'Input / Output',
              description: 'Reading from stdin and printing to stdout.',
              code: "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
              ref: ref,
              context: context,
            ),
            _ExampleCard(
              title: 'Lists & Loops',
              description: 'Iterating through a collection.',
              code: "void main() {\n  List<String> fruits = ['Apple', 'Banana', 'Cherry'];\n  for (var fruit in fruits) {\n    print('I like \$fruit');\n  }\n}",
              ref: ref,
              context: context,
            ),
            _ExampleCard(
              title: 'Classes',
              description: 'Basic object-oriented programming.',
              code: "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name and I am \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 25);\n  p.introduce();\n}",
              ref: ref,
              context: context,
            ),
            _ExampleCard(
              title: 'Async / Await',
              description: 'Handling asynchronous operations.',
              code: "Future<void> fetchData() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data loaded!');\n}\n\nvoid main() async {\n  print('Start');\n  await fetchData();\n  print('End');\n}",
              ref: ref,
              context: context,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final String code;
  final WidgetRef ref;
  final BuildContext context;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.code,
    required this.ref,
    required this.context,
  });

  void _loadExample() {
    final file = CodeFile(name: '\${title.replaceAll(' ', '_').toLowerCase()}.dart', content: code);
    ref.read(fileProvider.notifier).addFile(file);
    Fluttertoast.showToast(msg: "Loaded \$title");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black45,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: _loadExample,
          child: const Text('Load'),
        ),
      ),
    );
  }
}
