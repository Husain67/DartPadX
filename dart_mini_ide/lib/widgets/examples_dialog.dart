import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../utils/theme.dart';

class ExamplesDialog extends ConsumerWidget {
  const ExamplesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': "void main() {\n  print('Hello World!');\n}"
      },
      {
        'title': 'Variables & Types',
        'code': "void main() {\n  int age = 25;\n  double pi = 3.14;\n  String name = 'Dart';\n  bool isFun = true;\n  print('\$name is \$age years old. Fun? \$isFun');\n}"
      },
      {
        'title': 'Lists & Loops',
        'code': "void main() {\n  var fruits = ['Apple', 'Banana', 'Orange'];\n  for (var fruit in fruits) {\n    print('I like \$fruit');\n  }\n}"
      },
      {
        'title': 'Classes',
        'code': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, I am \$name');\n}\n\nvoid main() {\n  var p = Person('Alice');\n  p.greet();\n}"
      },
      {
        'title': 'Async / Await',
        'code': "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Data fetched!');\n}"
      },
    ];

    return AlertDialog(
      title: const Text('Examples Gallery', style: TextStyle(color: AppTheme.accentYellow)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: examples.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white24),
          itemBuilder: (ctx, i) => ListTile(
            title: Text(examples[i]['title']!, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              ref.read(fileProvider.notifier).addFile(
                name: "${examples[i]['title']!.replaceAll(' ', '_').toLowerCase()}.dart",
                content: examples[i]['code']!,
              );
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}
