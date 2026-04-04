import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/app_theme.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  final List<Map<String, String>> examples = const [
    {
      'title': 'Hello World',
      'description': 'A simple hello world program in Dart.',
      'code': '''void main() {
  print('Hello, World!');
}'''
    },
    {
      'title': 'Variables & Types',
      'description': 'Demonstrates basic variables and data types.',
      'code': '''void main() {
  String name = 'Dart';
  int year = 2011;
  double version = 3.5;
  bool isAwesome = true;

  print('Language: \$name');
  print('Created in: \$year');
  print('Version: \$version');
  print('Is it awesome? \$isAwesome');
}'''
    },
    {
      'title': 'Lists & Loops',
      'description': 'Working with lists and loops.',
      'code': '''void main() {
  List<String> fruits = ['Apple', 'Banana', 'Orange'];

  for (var fruit in fruits) {
    print('I love \$fruit');
  }
}'''
    },
    {
      'title': 'Classes & Objects',
      'description': 'Basic object-oriented programming.',
      'code': '''class Person {
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
}'''
    },
    {
      'title': 'Async / Await',
      'description': 'Using asynchronous programming with Futures.',
      'code': '''import 'dart:async';

Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return 'Data loaded successfully!';
}

void main() async {
  print('Fetching data...');
  var data = await fetchData();
  print(data);
}'''
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples Gallery'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: examples.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white12),
        itemBuilder: (context, index) {
          final example = examples[index];
          return Card(
            color: AppTheme.bgLight,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  example['title']!,
                  style: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  example['description']!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MarkdownBody(
                          data: '```dart\\n${example['code']!}\\n```',
                          styleSheet: MarkdownStyleSheet(
                            codeblockPadding: const EdgeInsets.all(0),
                            codeblockDecoration: const BoxDecoration(color: Colors.transparent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(fileProvider.notifier).createNewFile(
                              '${example['title']!.replaceAll(' ', '_').toLowerCase()}.dart',
                              example['code']!
                            );
                            Navigator.pop(context);
                            Fluttertoast.showToast(msg: "Example loaded");
                          },
                          icon: const Icon(Icons.file_download),
                          label: const Text('Open in Editor'),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
