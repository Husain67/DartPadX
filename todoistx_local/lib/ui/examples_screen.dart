import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_notifier.dart';
import '../theme/app_theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': '''void main() {
  print('Hello, World!');
}''',
      'Input/Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  // Simulating stdin since most APIs require pre-passed stdin
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
      'Lists': '''void main() {
  var fruits = ['Apple', 'Banana', 'Mango'];
  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}''',
      'Classes': '''class Person {
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
      'Async / Await': '''Future<void> fetchUserOrder() {
  return Future.delayed(
    const Duration(seconds: 2),
    () => print('Large Latte'),
  );
}

void main() async {
  print('Fetching order...');
  await fetchUserOrder();
  print('Order delivered!');
}''',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          itemCount: examples.length,
          itemBuilder: (context, index) {
            String title = examples.keys.elementAt(index);
            String code = examples.values.elementAt(index);

            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to load into editor'),
                trailing: const Icon(Icons.code, color: AppTheme.primaryAccent),
                onTap: () {
                  ref.read(filesProvider.notifier).createFile('${title.replaceAll(" ", "_").toLowerCase()}.dart', code);
                  final files = ref.read(filesProvider);
                  ref.read(activeFileIdProvider.notifier).state = files.last.id;
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
