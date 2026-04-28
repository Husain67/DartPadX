import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/file_provider.dart';
import '../../theme/app_theme.dart';

class ExamplesScreen extends ConsumerWidget {
  ExamplesScreen({super.key});

  final List<Map<String, String>> examples = [
    {
      'title': 'Hello World',
      'code': "void main() {\n  print('Hello, World!');\n}"
    },
    {
      'title': 'Variables & Math',
      'code': "void main() {\n  int a = 10;\n  int b = 20;\n  print('Sum of \$a and \$b is \${a + b}');\n}"
    },
    {
      'title': 'List Processing',
      'code': "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  var squared = numbers.map((n) => n * n).toList();\n  print('Original: \$numbers');\n  print('Squared: \$squared');\n}"
    },
    {
      'title': 'Classes & Objects',
      'code': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name and I am \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Jules', 25);\n  p.introduce();\n}"
    },
    {
      'title': 'Async / Await',
      'code': "Future<void> fetchUser() async {\n  print('Fetching user...');\n  await Future.delayed(Duration(seconds: 2));\n  print('User fetched!');\n}\n\nvoid main() async {\n  await fetchUser();\n  print('Done.');\n}"
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dart Examples Gallery')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.white.withValues(alpha: 0.05),
            child: ListTile(
              title: Text(example['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
              subtitle: Text(example['code']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () {
                  ref.read(fileProvider.notifier).addFile(
                    name: 'example_${index + 1}.dart',
                    content: example['code']!
                  );
                  Fluttertoast.showToast(msg: "Loaded ${example['title']}", backgroundColor: Colors.green);
                  Navigator.pop(context);
                },
                child: const Text('Load'),
              ),
            ),
          );
        },
      ),
    );
  }
}
