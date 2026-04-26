import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  ExamplesGallery({super.key});

  final Map<String, String> examples = {
    'Hello World': '''void main() {
  print('Hello, World!');
}''',
    'List Operations': '''void main() {
  var list = [1, 2, 3];
  list.add(4);
  print(list);

  var mapped = list.map((e) => e * 2).toList();
  print(mapped);
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
    'Async Await': '''Future<String> fetchUserData() async {
  await Future.delayed(Duration(seconds: 1));
  return 'User Data';
}

void main() async {
  print('Fetching...');
  var data = await fetchUserData();
  print(data);
}''',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final title = examples.keys.elementAt(index);
          final code = examples.values.elementAt(index);
          return Card(
            margin: const EdgeInsets.all(8),
            color: const Color(0xFF1a1a1a),
            child: ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
              subtitle: const Text('Tap to load into editor'),
              onTap: () {
                final safeTitle = title.replaceAll(' ', '_').toLowerCase();
                ref.read(fileProvider.notifier).addFile('$safeTitle.dart', code);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
