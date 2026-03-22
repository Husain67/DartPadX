import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/files_provider.dart';
import '../../utils/theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  final Map<String, String> examples = const {
    'Hello World': "void main() {\n  print('Hello, World!');\n}",
    'Input/Output': "import 'dart:io';\n\nvoid main() {\n  stdout.write('Enter your name: ');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
    'List & Loops': "void main() {\n  List<String> fruits = ['Apple', 'Banana', 'Orange'];\n  for (var fruit in fruits) {\n    print('I like \$fruit');\n  }\n}",
    'Class Example': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name and I am \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 30);\n  p.introduce();\n}",
    'Async Await': "import 'dart:async';\n\nFuture<void> fetchUserOrder() {\n  return Future.delayed(const Duration(seconds: 2), () => print('Large Latte'));\n}\n\nvoid main() async {\n  print('Fetching order...');\n  await fetchUserOrder();\n  print('Order fetched!');\n}",
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final title = examples.keys.elementAt(index);
          final code = examples.values.elementAt(index);
          return Card(
            color: AppTheme.darkBg,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(title, style: const TextStyle(color: AppTheme.yellowAccent, fontWeight: FontWeight.bold)),
              subtitle: Text(code.split('\n').take(2).join('\n') + '...', style: const TextStyle(fontFamily: 'monospace', color: Colors.white54)),
              trailing: const Icon(Icons.add_to_photos, color: AppTheme.whiteCream),
              onTap: () {
                final id = ref.read(filesProvider.notifier).createFile('$title.dart', code);
                ref.read(activeFileIdProvider.notifier).state = id;
                Navigator.pop(context); // Close gallery
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded $title')));
              },
            ),
          );
        },
      ),
    );
  }
}
