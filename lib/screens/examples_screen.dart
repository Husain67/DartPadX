import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            ref,
            'Hello World',
            '''
void main() {
  print('Hello World!');
}
''',
          ),
          _buildExampleCard(
            context,
            ref,
            'Basic Input/Output',
            '''
import 'dart:io';

void main() {
  print('Enter your name:');
  // Mocking stdin for IDE execution
  String name = stdin.readLineSync() ?? 'Guest';
  print('Hello, \$name!');
}
''',
          ),
           _buildExampleCard(
            context,
            ref,
            'List Operations',
            '''
void main() {
  List<int> numbers = [1, 2, 3, 4, 5];
  var doubled = numbers.map((n) => n * 2).toList();
  print('Original: \$numbers');
  print('Doubled: \$doubled');
}
''',
          ),
          _buildExampleCard(
            context,
            ref,
            'Classes and Objects',
            '''
class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var person = Person('Alice', 25);
  person.introduce();
}
''',
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(BuildContext context, WidgetRef ref, String title, String code) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(data: '```dart\\n\$code\\n```'),
          ),
          OverflowBar(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(fileProvider.notifier).addFile(title.replaceAll(' ', '_').toLowerCase() + '.dart', code);
                  Navigator.pop(context);
                },
                child: const Text('Import Example'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
