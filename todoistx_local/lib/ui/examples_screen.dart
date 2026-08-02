import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import 'theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': '''void main() {
  print('Hello World!');
}''',
      'Input/Output (Simulated)': '''import 'dart:io';

void main() {
  print('Enter your name:');
  // Note: stdin.readLineSync() blocks in most APIs without predefined stdin.
  // We'll simulate a greeting:
  String name = 'DartMini User';
  print('Hello \$name!');
}''',
      'List operations': '''void main() {
  List<int> numbers = [5, 2, 8, 1, 9];
  numbers.sort();
  print('Sorted: \$numbers');

  final doubled = numbers.map((n) => n * 2).toList();
  print('Doubled: \$doubled');
}''',
      'Classes & OOP': '''class Animal {
  String name;
  Animal(this.name);

  void speak() {
    print('\$name makes a sound.');
  }
}

class Dog extends Animal {
  Dog(String name) : super(name);

  @override
  void speak() {
    print('\$name barks!');
  }
}

void main() {
  var dog = Dog('Rex');
  dog.speak();
}''',
      'Async/Await': '''Future<void> fetchData() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 1));
  print('Data loaded!');
}

void main() async {
  print('Start');
  await fetchData();
  print('End');
}''',
    };

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Dart Examples'),
      ),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final key = examples.keys.elementAt(index);
          final code = examples[key]!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.backgroundEnd,
            child: ListTile(
              title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.file_download, color: AppTheme.primaryAccent),
                onPressed: () {
                  final safeName = key.replaceAll(' ', '_') + '.dart';
                  ref.read(fileProvider.notifier).importFile(safeName, code);
                  Fluttertoast.showToast(msg: "Loaded $key");
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
