import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class ExamplesDialog extends ConsumerWidget {
  const ExamplesDialog({super.key});

  final List<Map<String, String>> examples = const [
    {
      'name': 'Hello World',
      'code': 'void main() {\n  print("Hello, World!");\n}'
    },
    {
      'name': 'Async Future',
      'code': 'Future<void> main() async {\n  print("Fetching data...");\n  await Future.delayed(Duration(seconds: 2));\n  print("Data loaded!");\n}'
    },
    {
      'name': 'Class Example',
      'code': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.greet();\n}'
    },
    {
      'name': 'Stream',
      'code': 'void main() async {\n  Stream<int> countStream = Stream.periodic(Duration(seconds: 1), (x) => x).take(5);\n  await for (int i in countStream) {\n    print(i);\n  }\n}'
    },
    {
      'name': 'List Manipulation',
      'code': 'void main() {\n  var list = [1, 2, 3];\n  var doubled = list.map((e) => e * 2).toList();\n  print(doubled);\n}'
    },
    {
      'name': 'JSON Parsing',
      'code': 'import "dart:convert";\n\nvoid main() {\n  var jsonString = \'{"name": "Dart", "age": 10}\';\n  var parsed = jsonDecode(jsonString);\n  print(parsed["name"]);\n}'
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Code Examples'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: examples.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final example = examples[index];
            return ListTile(
              title: Text(example['name']!, style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(fileProvider.notifier).addFile(
                  '${example['name']!.replaceAll(' ', '_').toLowerCase()}.dart',
                  example['code']!
                );
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
