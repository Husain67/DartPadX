import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  final List<Map<String, String>> examples = const [
    {
      'title': 'Hello World',
      'code': '''void main() {
  print('Hello, World!');
}'''
    },
    {
      'title': 'Variables & Math',
      'code': '''void main() {
  int a = 10;
  int b = 20;
  print('Sum: \${a + b}');
}'''
    },
    {
      'title': 'Lists',
      'code': '''void main() {
  List<int> numbers = [1, 2, 3, 4, 5];
  for (int num in numbers) {
    print(num * 2);
  }
}'''
    },
    {
      'title': 'Classes',
      'code': '''class Person {
  String name;
  Person(this.name);
  void greet() => print('Hi, I am \$name');
}

void main() {
  var p = Person('DartMini');
  p.greet();
}'''
    },
    {
      'title': 'Async/Await',
      'code': '''import 'dart:async';

Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 1));
  print('Data loaded!');
}'''
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples Gallery')),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            leading: const Icon(Icons.code, color: Color(0xFFFACC15)),
            title: Text(example['title']!),
            subtitle: Text(
              example['code']!.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.download, size: 20),
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
              final activeFile = ref.read(fileProvider.notifier).activeFile;
              if (activeFile != null) {
                final cleanTitle = example['title']!.replaceAll(' ', '_').toLowerCase();

                // Update Riverpod State directly through a dedicated public method
                ref.read(fileProvider.notifier).updateActiveFileContent(example['code']!);
                ref.read(fileProvider.notifier).renameActiveFile("${cleanTitle}.dart");

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Loaded "${example["title"]}" example')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
