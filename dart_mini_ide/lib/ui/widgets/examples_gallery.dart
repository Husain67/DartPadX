import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../theme/app_theme.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  final Map<String, String> examples = const {
    'Hello World': '''
void main() {
  print('Hello, World!');
}
''',
    'Input/Output': '''
import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Welcome, \$name!');
}
''',
    'List': '''
void main() {
  var list = [1, 2, 3];
  list.add(4);
  list.forEach((e) => print(e));
}
''',
    'Class': '''
class Person {
  String name;
  int age;
  Person(this.name, this.age);
  void introduce() => print('Hi, I am \$name, \$age years old.');
}

void main() {
  var p = Person('Alice', 25);
  p.introduce();
}
''',
    'Async': '''
Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 1));
  print('Data loaded!');
}
'''
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          String key = examples.keys.elementAt(index);
          String value = examples.values.elementAt(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceColor,
            child: ListTile(
              title: Text(key),
              trailing: IconButton(
                icon: const Icon(Icons.add, color: AppTheme.accentYellow),
                onPressed: () {
                  ref.read(fileProvider.notifier).createNewFile('\$key.dart', value);
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
