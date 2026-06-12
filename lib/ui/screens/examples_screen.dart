import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../providers/file_notifier.dart';
import '../../theme/app_theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  final List<Map<String, String>> examples = const [
    {
      'title': 'Hello World',
      'description': 'A simple program that prints Hello World.',
      'code': '''
void main() {
  print('Hello World!');
}
'''
    },
    {
      'title': 'Input/Output',
      'description': 'Reads from standard input and prints the result.',
      'code': '''
import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  if (name != null) {
    print('Hello, \$name!');
  }
}
'''
    },
    {
      'title': 'List Operations',
      'description': 'Demonstrates basic list operations and loops.',
      'code': '''
void main() {
  List<int> numbers = [1, 2, 3, 4, 5];

  // Multiply each number by 2
  var doubled = numbers.map((n) => n * 2).toList();

  print('Original: \$numbers');
  print('Doubled: \$doubled');

  for (var num in doubled) {
    if (num > 5) {
      print('\$num is greater than 5');
    }
  }
}
'''
    },
    {
      'title': 'Classes and Objects',
      'description': 'A simple class definition and instantiation.',
      'code': '''
class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var person = Person('Alice', 30);
  person.introduce();
}
'''
    },
    {
      'title': 'Async / Await',
      'description': 'Using asynchronous programming in Dart.',
      'code': '''
Future<String> fetchUserOrder() {
  // Imagine that this function is fetching user info from another service or database.
  return Future.delayed(const Duration(seconds: 2), () => 'Large Latte');
}

void main() async {
  print('Fetching order...');
  var order = await fetchUserOrder();
  print('Your order is: \$order');
}
'''
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples Gallery'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: ListView.builder(
          itemCount: examples.length,
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            final example = examples[index];
            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: ExpansionTile(
                title: Text(
                  example['title']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
                ),
                subtitle: Text(example['description']!),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.black26,
                    width: double.infinity,
                    child: MarkdownBody(
                      data: '```dart\n${example['code']}\n```',
                      styleSheet: MarkdownStyleSheet(
                        code: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.transparent),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  ButtonBar(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.file_copy, color: AppTheme.primaryAccent),
                        label: const Text('Load into Editor', style: TextStyle(color: AppTheme.primaryAccent)),
                        onPressed: () {
                          ref.read(fileProvider.notifier).createFile(
                            '${example['title']!.replaceAll(' ', '_').toLowerCase()}.dart',
                            content: example['code']!,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
