import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': '''void main() {
  print('Hello, World!');
}''',
      'Input/Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
      'List': '''void main() {
  var list = [1, 2, 3, 4, 5];
  var mapped = list.map((n) => n * 2);
  print('Original: \$list');
  print('Mapped: \$mapped');
}''',
      'Class': '''class Person {
  String name;
  int age;
  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name, \$age years old.');
  }
}

void main() {
  var p = Person('Alice', 30);
  p.introduce();
}''',
      'Async': '''Future<void> fetchUserOrder() {
  return Future.delayed(const Duration(seconds: 2), () => print('Large Latte'));
}

void main() async {
  print('Fetching user order...');
  await fetchUserOrder();
  print('Done.');
}''',
    };

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Examples Gallery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: examples.length,
              itemBuilder: (context, index) {
                final title = examples.keys.elementAt(index);
                final code = examples.values.elementAt(index);
                return ListTile(
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  onTap: () {
                    final fileNotifier = ref.read(fileProvider.notifier);
                    fileNotifier.createNewFile();
                    final newActiveFile = ref.read(fileProvider).activeFile;
                    if (newActiveFile != null) {
                      fileNotifier.forceUpdateFile(newActiveFile.copyWith(
                        name: '${title.replaceAll(' ', '_')}.dart',
                        content: code,
                      ));
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
