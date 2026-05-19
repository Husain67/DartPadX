import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Example {
  final String title;
  final String description;
  final String code;

  const Example({required this.title, required this.description, required this.code});
}

const List<Example> _examples = [
  Example(
    title: 'Hello World',
    description: 'A simple print statement to get started.',
    code: '''void main() {
  print('Hello, World!');
}''',
  ),
  Example(
    title: 'Input & Output',
    description: 'Reading from stdin and writing to stdout.',
    code: '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
  ),
  Example(
    title: 'List Operations',
    description: 'Mapping and filtering a list of integers.',
    code: '''void main() {
  var numbers = [1, 2, 3, 4, 5];
  var squared = numbers.map((n) => n * n).toList();
  var evens = squared.where((n) => n % 2 == 0);
  print('Original: \$numbers');
  print('Squared: \$squared');
  print('Even squares: \$evens');
}''',
  ),
  Example(
    title: 'Classes & Objects',
    description: 'Defining a simple class with a method.',
    code: '''class Person {
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
}''',
  ),
  Example(
    title: 'Async / Await',
    description: 'Simulating an asynchronous network request.',
    code: '''Future<String> fetchUserOrder() {
  return Future.delayed(
    const Duration(seconds: 2),
    () => 'Large Latte',
  );
}

void main() async {
  print('Fetching user order...');
  var order = await fetchUserOrder();
  print('Your order is: \$order');
}''',
  ),
];

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _examples.length,
      itemBuilder: (context, index) {
        final example = _examples[index];
        return Card(
          color: AppTheme.backgroundGradientEnd,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ExpansionTile(
            title: Text(example.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
            subtitle: Text(example.description, style: const TextStyle(color: Colors.grey)),
            iconColor: AppTheme.primaryYellow,
            collapsedIconColor: Colors.grey,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.black,
                child: Text(
                  example.code,
                  style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final safeName = example.title.replaceAll(' ', '_').toLowerCase();
                      ref.read(fileProvider.notifier).addFile('$safeName.dart', example.code);
                      Fluttertoast.showToast(msg: "Added $safeName.dart", backgroundColor: Colors.green);
                      Navigator.pop(context); // Close settings screen to go back to main editor
                    },
                    icon: const Icon(Icons.file_download, color: Colors.black),
                    label: const Text('Load into Editor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
