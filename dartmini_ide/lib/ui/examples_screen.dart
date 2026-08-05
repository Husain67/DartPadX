import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello, World!');\n}",
      'Input/Output': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
      'List Example': "void main() {\n  List<String> fruits = ['Apple', 'Banana', 'Cherry'];\n  for (var fruit in fruits) {\n    print('I like \$fruit');\n  }\n}",
      'Class Example': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name and I am \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 30);\n  p.introduce();\n}",
      'Async/Await': "Future<void> fetchUserOrder() {\n  return Future.delayed(const Duration(seconds: 2), () => print('Large Latte'));\n}\n\nvoid main() async {\n  print('Fetching order...');\n  await fetchUserOrder();\n  print('Order delivered!');\n}",
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final key = examples.keys.elementAt(index);
          final value = examples.values.elementAt(index);
          return ListTile(
            title: Text(key),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ref.read(filesProvider.notifier).addFile('${key.replaceAll(' ', '_').toLowerCase()}.dart', value);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
