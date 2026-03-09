import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'desc': 'A basic program that prints text.',
        'code': 'void main() {\n  print(\'Hello World!\');\n}\n',
      },
      {
        'title': 'Input / Output',
        'desc': 'Demonstrates reading from stdin using custom APIs.',
        'code': 'import \'dart:io\';\n\nvoid main() {\n  String? name = stdin.readLineSync();\n  print(\'Hello, \$name!\');\n}\n',
      },
      {
        'title': 'List',
        'desc': 'Working with lists and loops.',
        'code': 'void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var num in list) {\n    print(num * 2);\n  }\n}\n',
      },
      {
        'title': 'Class',
        'desc': 'Basic OOP in Dart.',
        'code': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print(\'Hi, I am \$name\');\n}\n\nvoid main() {\n  var p = Person(\'Alice\');\n  p.greet();\n}\n',
      },
      {
        'title': 'Async',
        'desc': 'Asynchronous programming using Futures.',
        'code': 'void main() async {\n  print(\'Fetching data...\');\n  await Future.delayed(Duration(seconds: 1));\n  print(\'Data fetched!\');\n}\n',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Examples Gallery'),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final ex = examples[index];
            return Card(
              color: AppTheme.backgroundEnd,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white12, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  ex['title']!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  ex['desc']!,
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pillBackground,
                    foregroundColor: AppTheme.pureBlack,
                  ),
                  onPressed: () {
                    final filename = '${ex['title']!.toLowerCase().replaceAll(' ', '_')}.dart';
                    ref.read(fileProvider.notifier).createFile(filename, ex['code']!);
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Loaded ${ex["title"]}');
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
