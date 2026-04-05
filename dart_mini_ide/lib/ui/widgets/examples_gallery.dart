import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  final Map<String, String> _examples = const {
    'Hello World': '''void main() {
  print('Hello, World!');
}''',
    'Input/Output': '''import 'dart:io';

void main() {
  stdout.write('What is your name? ');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
    'List Operations': '''void main() {
  var numbers = [1, 2, 3, 4, 5];
  var doubled = numbers.map((n) => n * 2).toList();
  print('Original: \$numbers');
  print('Doubled: \$doubled');
}''',
    'Class Example': '''class Person {
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
    'Async Await': '''Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched successfully!');
}''',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _examples.length,
        itemBuilder: (context, index) {
          final title = _examples.keys.elementAt(index);
          final code = _examples.values.elementAt(index);
          return Card(
            color: const Color(0xFF1a1a1a),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(title, style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.download, color: Colors.white),
              onTap: () {
                ref.read(fileProvider.notifier).createNewFile('${title.replaceAll(' ', '_').toLowerCase()}.dart', code);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}