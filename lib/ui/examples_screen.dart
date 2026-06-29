import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  final Map<String, String> _examples = const {
    'Hello World': '''void main() {
  print('Hello, World!');
}''',
    'List Operations': '''void main() {
  var list = [1, 2, 3];
  list.add(4);
  print('List: \$list');
  print('Sum: \${list.reduce((a, b) => a + b)}');
}''',
    'Classes': '''class Person {
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
    'Async Await': '''Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched!');
}'''
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Examples'),
        backgroundColor: AppTheme.appBarColor,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          itemCount: _examples.length,
          itemBuilder: (context, index) {
            String title = _examples.keys.elementAt(index);
            String code = _examples.values.elementAt(index);

            return ExpansionTile(
              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconColor: AppTheme.primaryAccent,
              collapsedIconColor: Colors.white,
              children: [
                Container(
                  color: Colors.black45,
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: MarkdownBody(
                    data: '```dart\n$code\n```',
                    styleSheet: MarkdownStyleSheet(
                      codeblockDecoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(fileProvider.notifier).createFile('${title.replaceAll(" ", "_").toLowerCase()}.dart', content: code);
                        Navigator.pop(context); // Close examples screen
                        Navigator.pop(context); // Close settings screen
                      },
                      icon: const Icon(Icons.file_copy, color: Colors.black),
                      label: const Text('Load into Editor', style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
