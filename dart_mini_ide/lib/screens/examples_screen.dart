import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/file_provider.dart';

class ExampleModel {
  final String title;
  final String description;
  final String code;

  ExampleModel({required this.title, required this.description, required this.code});
}

final List<ExampleModel> _examples = [
  ExampleModel(
    title: 'Hello World',
    description: 'A simple program that prints Hello World.',
    code: '''void main() {
  print('Hello, World!');
}''',
  ),
  ExampleModel(
    title: 'Input / Output',
    description: 'Example of reading from stdin.',
    code: '''import 'dart:io';

void main() {
  print('Enter your name: ');
  // Note: custom compilers might not support interactive stdin,
  // but you can provide stdin in Custom API preset configs.
  String? name = stdin.readLineSync();
  print('Hello, ${name ?? "Guest"}!');
}''',
  ),
  ExampleModel(
    title: 'Lists & Loops',
    description: 'Working with collections in Dart.',
    code: '''void main() {
  List<String> fruits = ['Apple', 'Banana', 'Cherry'];

  for (var fruit in fruits) {
    print('I like $fruit');
  }

  var numbers = [1, 2, 3, 4, 5];
  var evenNumbers = numbers.where((n) => n % 2 == 0).toList();
  print('Even numbers: $evenNumbers');
}''',
  ),
  ExampleModel(
    title: 'Classes & Objects',
    description: 'Object-oriented programming basics.',
    code: '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am $name and I am $age years old.');
  }
}

void main() {
  var p1 = Person('Alice', 28);
  p1.introduce();
}''',
  ),
  ExampleModel(
    title: 'Async & Await',
    description: 'Simulating asynchronous operations.',
    code: '''Future<String> fetchUser() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  return 'User: Jane Doe';
}

void main() async {
  print('Start');
  var user = await fetchUser();
  print(user);
  print('End');
}''',
  ),
];

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples Library'),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _examples.length,
          itemBuilder: (context, index) {
            final example = _examples[index];
            return Card(
              color: Colors.white12,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(example.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(example.description, style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    // Create a new tab with this content
                    ref.read(fileProvider.notifier).importFile('${example.title.replaceAll(' ', '_')}.dart', example.code);
                    Navigator.pop(context);
                  },
                  child: const Text('Load'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
