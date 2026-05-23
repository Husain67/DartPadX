import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': '''
void main() {
  print('Hello World!');
}
'''
      },
      {
        'title': 'Input / Output',
        'code': '''
import 'dart:io';

void main() {
  print('Enter something:');
  String? input = stdin.readLineSync();
  print('You entered: \$input');
}
'''
      },
      {
        'title': 'List Operations',
        'code': '''
void main() {
  final list = [1, 2, 3, 4, 5];
  final doubled = list.map((e) => e * 2).toList();
  print('Original: \$list');
  print('Doubled: \$doubled');
}
'''
      },
      {
        'title': 'Simple Class',
        'code': '''
class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void greet() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p = Person('Alice', 28);
  p.greet();
}
'''
      },
      {
        'title': 'Async/Await',
        'code': '''
Future<void> fetchUserOrder() {
  return Future.delayed(const Duration(seconds: 2), () => print('Large Latte'));
}

void main() async {
  print('Fetching order...');
  await fetchUserOrder();
  print('Order fetched!');
}
'''
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
            color: const Color(0xFF1E1E1E),
            child: ListTile(
              title: Text(example['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFACC15)),
              onTap: () {
                final safeTitle = example['title']!.replaceAll(' ', '_');
                ref.read(fileProvider.notifier).addFile('example_$safeTitle.dart', example['code']!);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
