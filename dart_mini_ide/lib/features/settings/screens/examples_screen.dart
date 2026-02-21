import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/features/editor/providers/editor_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  static const Map<String, String> examples = {
    'Hello World': 'void main() {\n  print("Hello, World!");\n}',
    'Input/Output': 'import "dart:io";\n\nvoid main() {\n  stdout.write("Enter name: ");\n  String? name = stdin.readLineSync();\n  print("Hello, \$name!");\n}',
    'List & Loop': 'void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var i in list) {\n    print(i * 2);\n  }\n}',
    'Class': 'class Person {\n  String name;\n  int age;\n  Person(this.name, this.age);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("Alice", 30);\n  p.greet();\n}',
    'Async': 'Future<void> main() async {\n  print("Fetching data...");\n  await Future.delayed(Duration(seconds: 2));\n  print("Data loaded!");\n}',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples')),
      body: ListView(
        children: examples.entries.map((e) {
          return ListTile(
            title: Text(e.key),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ref.read(editorProvider.notifier).importFile('${e.key.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_").toLowerCase()}.dart', e.value);
              Navigator.pop(context); // Close examples
              Navigator.pop(context); // Close settings
              Fluttertoast.showToast(msg: "Example loaded");
            },
          );
        }).toList(),
      ),
    );
  }
}
