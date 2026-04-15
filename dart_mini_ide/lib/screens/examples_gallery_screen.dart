import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';

class ExamplesGalleryScreen extends ConsumerWidget {
  const ExamplesGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': "void main() {\n  print('Hello, World!');\n}"
      },
      {
        'title': 'Input / Output',
        'code': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}"
      },
      {
        'title': 'List Comprehension',
        'code': "void main() {\n  final list = [1, 2, 3, 4, 5];\n  final squares = [for (var i in list) i * i];\n  print('Squares: \$squares');\n}"
      },
      {
        'title': 'Class Example',
        'code': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void greet() => print('Hi, I am \$name, \$age years old.');\n}\n\nvoid main() {\n  var p = Person('Alice', 28);\n  p.greet();\n}"
      },
      {
        'title': 'Async/Await',
        'code': "Future<void> fetchData() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data fetched!');\n}\n\nvoid main() async {\n  await fetchData();\n}"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return Card(
            color: const Color(0xFF151515),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white12),
            ),
            child: ListTile(
              title: Text(example['title']!, style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF252525),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final filename = '${example['title']!.replaceAll(' ', '_').toLowerCase()}.dart';
                  ref.read(fileProvider.notifier).createFile(filename, example['code']!);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: "Loaded Example: \${example['title']}");
                },
                child: const Text('Load'),
              ),
            ),
          );
        },
      ),
    );
  }
}
