import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': '''void main() {
  print('Hello, DartMini!');
}'''
      },
      {
        'title': 'List Operations',
        'code': '''void main() {
  final list = [1, 2, 3, 4, 5];
  final doubled = list.map((e) => e * 2).toList();
  print('Original: \$list');
  print('Doubled: \$doubled');
}'''
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
  final p = Person('Jules', 25);
  p.introduce();
}'''
      },
      {
         'title': 'Async / Await',
         'code': '''import 'dart:async';

Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(const Duration(seconds: 1));
  print('Data loaded!');
}'''
      }
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return Card(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: const Color(0xFF1A1A1A),
             child: ListTile(
                title: Text(example['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
                subtitle: const Text('Tap to load into editor'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                   ref.read(fileProvider.notifier).addFile(
                      name: "${example['title']!.replaceAll(' ', '_').toLowerCase()}.dart",
                      content: example['code']!
                   );
                   Navigator.pop(context);
                },
             ),
          );
        },
      ),
    );
  }
}
