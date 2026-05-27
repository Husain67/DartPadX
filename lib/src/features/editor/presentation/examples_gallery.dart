import 'package:flutter/material.dart';

class ExamplesGallery extends StatelessWidget {
  const ExamplesGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final examples = [
      {'name': 'Hello World', 'code': "void main() {\n  print('Hello, World!');\n}"},
      {'name': 'Input/Output', 'code': "import 'dart:io';\n\nvoid main() {\n  stdout.write('Enter your name: ');\n  var name = stdin.readLineSync();\n  print('Hello, \$name!');\n}"},
      {'name': 'List Operations', 'code': "void main() {\n  var numbers = [1, 2, 3, 4, 5];\n  var doubled = numbers.map((n) => n * 2).toList();\n  print(doubled);\n}"},
      {'name': 'Class Example', 'code': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name, \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 30);\n  p.introduce();\n}"},
      {'name': 'Async / Await', 'code': "Future<void> main() async {\n  print('Fetching data...');\n  var result = await fetchData();\n  print(result);\n}\n\nFuture<String> fetchData() async {\n  await Future.delayed(Duration(seconds: 2));\n  return 'Data loaded successfully!';\n}"},
    ];

    return AlertDialog(
      title: const Text('Examples Gallery'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final ex = examples[index];
            return ListTile(
              title: Text(ex['name']!),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(context, ex);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
