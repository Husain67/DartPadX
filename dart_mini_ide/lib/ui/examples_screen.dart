import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/file_provider.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  static const List<Map<String, String>> _examples = [
    {
      'title': 'Hello World',
      'code': '''void main() {
  print('Hello World!');
}''',
    },
    {
      'title': 'List & Map',
      'code': '''void main() {
  final list = [1, 2, 3];
  final map = {'a': 1, 'b': 2};
  print(list);
  print(map);
}''',
    },
    {
      'title': 'Class Example',
      'code': '''class Person {
  String name;
  Person(this.name);
  void sayHello() => print('Hello, I am \$name');
}

void main() {
  final p = Person('DartMini');
  p.sayHello();
}''',
    },
    {
      'title': 'Async / Await',
      'code': '''Future<String> fetchUser() async {
  await Future.delayed(Duration(seconds: 1));
  return 'User Data';
}

void main() async {
  print('Fetching...');
  print(await fetchUser());
}''',
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples Gallery'),
      ),
      body: ListView.builder(
        itemCount: _examples.length,
        itemBuilder: (context, index) {
          final ex = _examples[index];
          return ListTile(
            leading: const Icon(Icons.code, color: AppTheme.primaryAccent),
            title: Text(ex['title']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(fileProvider.notifier).addNewFile(
                name: '\${ex["title"]!.replaceAll(" ", "_").toLowerCase()}.dart',
                content: ex['code']!.replaceAll('\\\$', '\$'), // Correctly resolve variables
              );
              Navigator.pop(context); // Close Examples
              Navigator.pop(context); // Close Settings
            },
          );
        },
      ),
    );
  }
}
