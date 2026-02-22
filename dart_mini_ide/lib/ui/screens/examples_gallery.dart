import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../core/theme.dart';

class ExamplesGallery extends ConsumerWidget {
  ExamplesGallery({super.key});

  final List<Map<String, String>> examples = [
    {
      'title': 'Hello World',
      'code': "void main() {\n  print('Hello, World!');\n}"
    },
    {
      'title': 'Input/Output',
      'code': "import 'dart:io';\n\nvoid main() {\n  stdout.write('Enter your name: ');\n  // Note: Stdin needs to be provided in Input tab\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}"
    },
    {
      'title': 'List & Loop',
      'code': "void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var i in list) {\n    print(i * i);\n  }\n}"
    },
    {
      'title': 'Class & Object',
      'code': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name and I am \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 30);\n  p.introduce();\n}"
    },
    {
      'title': 'Async Future',
      'code': "Future<void> main() async {\n  print('Fetching data...');\n  var data = await fetchData();\n  print('Data: \$data');\n}\n\nFuture<String> fetchData() async {\n  await Future.delayed(Duration(seconds: 2));\n  return 'Success';\n}"
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            title: Text(example['title']!, style: const TextStyle(color: Colors.white)),
            leading: const Icon(Icons.code, color: AppTheme.accentYellow),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              final name = "${example['title']!.replaceAll(RegExp(r'[ /&]'), '_')}.dart";
              ref.read(fileProvider.notifier).importFile(name, example['code']!);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
