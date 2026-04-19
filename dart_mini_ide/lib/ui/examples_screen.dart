import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme.dart';
import '../providers/file_provider.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': "void main() {\n  print('Hello, World!');\n}"
      },
      {
        'title': 'Variables and Math',
        'code': "void main() {\n  int a = 5;\n  int b = 10;\n  print('Sum of \$a and \$b is \${a + b}');\n}"
      },
      {
        'title': 'List and Loops',
        'code': "void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var num in list) {\n    print('Number: \$num');\n  }\n}"
      },
      {
        'title': 'Classes and Objects',
        'code': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name, \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 25);\n  p.introduce();\n}"
      },
      {
        'title': 'Async/Await',
        'code': "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data fetched!');\n}"
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples'),
      ),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            leading: const Icon(Icons.code, color: AppTheme.accentYellow),
            title: Text(example['title']!),
            subtitle: Text('${example['code']!.replaceAll('\n', ' ').substring(0, 30)}...'),
            onTap: () {
              final filename = '${example['title']!.replaceAll(' ', '_').toLowerCase()}.dart';
              ref.read(fileProvider.notifier).createNewFile(
                title: filename,
                content: example['code'],
              );
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Loaded ${example['title']}");
            },
          );
        },
      ),
    );
  }
}
