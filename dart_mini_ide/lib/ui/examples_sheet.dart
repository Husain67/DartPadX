import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesSheet extends ConsumerWidget {
  const ExamplesSheet({super.key});

  final Map<String, String> _examples = const {
    'Hello World': '''void main() {
  print('Hello, World!');
}''',
    'Input/Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  // String? name = stdin.readLineSync();
  // print('Hello, \$name!');
  print('Hello, Dart Mini!');
}''',
    'List & Loop': '''void main() {
  var fruits = ['Apple', 'Banana', 'Orange'];
  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}''',
    'Class': '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p = Person('Alice', 25);
  p.introduce();
}''',
    'Async': '''Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched!');
}'''
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Examples Gallery',
                style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _examples.length,
              itemBuilder: (context, index) {
                String key = _examples.keys.elementAt(index);
                String code = _examples[key]!;
                return Card(
                  color: const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.add_box, color: Color(0xFFFACC15)),
                    onTap: () {
                      ref.read(fileProvider.notifier).newFile();
                      ref.read(fileProvider.notifier).updateActiveFileContent(code);
                      ref.read(fileProvider.notifier).renameActiveFile('${key.replaceAll(' ', '_').toLowerCase()}.dart');
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
