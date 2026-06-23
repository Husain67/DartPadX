import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class ExamplesSheet extends ConsumerWidget {
  const ExamplesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': 'void main() {\n  print("Hello, World!");\n}\n'
      },
      {
        'title': 'Input/Output',
        'code': 'import "dart:io";\n\nvoid main() {\n  stdout.write("Enter your name: ");\n  String? name = stdin.readLineSync();\n  print("Hello, \$name!");\n}\n'
      },
      {
        'title': 'List',
        'code': 'void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (int num in numbers) {\n    print("Number: \$num");\n  }\n}\n'
      },
      {
        'title': 'Class',
        'code': 'class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print("Hi, I am \$name and I am \$age years old.");\n  }\n}\n\nvoid main() {\n  var p = Person("Alice", 25);\n  p.introduce();\n}\n'
      },
      {
        'title': 'Async',
        'code': 'Future<void> fetchUserOrder() {\n  // Imagine that this function is fetching user info from another service or database.\n  return Future.delayed(const Duration(seconds: 2), () => print("Large Latte"));\n}\n\nvoid main() async {\n  print("Fetching user order...");\n  await fetchUserOrder();\n  print("Done");\n}\n'
      },
    ];

    return Container(
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            title: Text(example['title']!, style: const TextStyle(color: Colors.white)),
            onTap: () {
              ref.read(fileProvider.notifier).importFile('${example['title']}.dart', example['code']!);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
