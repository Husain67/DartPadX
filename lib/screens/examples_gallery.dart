import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  final List<Map<String, String>> _examples = const [
    {
      'title': 'Hello World',
      'code': '''
void main() {
  print('Hello, DartMini!');
}
'''
    },
    {
      'title': 'User Input (stdin)',
      'code': '''
import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}
'''
    },
    {
      'title': 'Async / Await',
      'code': '''
import 'dart:async';

Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched successfully!');
}
'''
    },
    {
      'title': 'Lists & Classes',
      'code': '''
class Person {
  String name;
  int age;
  Person(this.name, this.age);
}

void main() {
  List<Person> people = [
    Person('Alice', 25),
    Person('Bob', 30),
  ];

  for (var p in people) {
    print('\${p.name} is \${p.age} years old.');
  }
}
'''
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _examples.length,
        itemBuilder: (context, index) {
          final ex = _examples[index];
          return Card(
            color: const Color(0xFF111111),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(ex['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Tap to load into editor'),
              trailing: const Icon(Icons.download, color: Color(0xFFFACC15)),
              onTap: () {
                final String safeName = ex['title']!.replaceAll(' ', '_');
                ref.read(fileProvider.notifier).addFile('${safeName}.dart', content: ex['code']!);
                Navigator.pop(context); // Close gallery
              },
            ),
          );
        },
      ),
    );
  }
}
