import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_provider.dart';
import '../theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': '''void main() {
  print('Hello, World!');
}''',
      },
      {
        'title': 'Variables & Data Types',
        'code': '''void main() {
  int age = 25;
  double height = 5.9;
  String name = 'Alice';
  bool isStudent = true;

  print('Name: \$name, Age: \$age, Height: \$height, Student: \$isStudent');
}''',
      },
      {
        'title': 'List & Loop',
        'code': '''void main() {
  List<String> fruits = ['Apple', 'Banana', 'Cherry'];

  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}''',
      },
      {
        'title': 'Classes & Objects',
        'code': '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p1 = Person('Bob', 30);
  p1.introduce();
}''',
      },
      {
        'title': 'Async / Await',
        'code': '''import 'dart:async';

Future<void> main() async {
  print('Fetching data...');
  var data = await fetchData();
  print('Data received: \$data');
}

Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return 'Secret Info';
}''',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples Gallery'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final example = examples[index];
            return Card(
              color: Colors.black45,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(example['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to open in editor', style: TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.accentYellow, size: 16),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile(
                        name: "${example['title']!.replaceAll(' ', '_').toLowerCase()}.dart",
                        content: example['code']!,
                      );
                  Navigator.pop(context); // Close Examples Screen
                  Navigator.pop(context); // Close Settings Screen (assuming it was opened from there)
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
