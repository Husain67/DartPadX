import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ExamplesDialog extends ConsumerWidget {
  const ExamplesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello World!");\n}',
      'Input/Output': 'import "dart:io";\n\nvoid main() {\n  print("Enter your name:");\n  String? name = stdin.readLineSync();\n  print("Hello, \$name!");\n}',
      'List Example': 'void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var num in numbers) {\n    print("Number: \$num");\n  }\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("DartMini");\n  p.greet();\n}',
      'Async Example': 'Future<void> fetch() async {\n  await Future.delayed(Duration(seconds: 1));\n  print("Data fetched");\n}\n\nvoid main() async {\n  print("Fetching...");\n  await fetch();\n}'
    };

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: examples.length,
          itemBuilder: (context, index) {
            String title = examples.keys.elementAt(index);
            String code = examples.values.elementAt(index);
            return ListTile(
              title: Text(title, style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(fileProvider.notifier).addFile('\${title.replaceAll(" ", "_")}.dart', code);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Example loaded");
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
