import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/file_model.dart';
import '../../providers/file_provider.dart';
import '../theme.dart';

class ExamplesDialog extends ConsumerWidget {
  const ExamplesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello DartMini!');\n}",
      'Input/Output': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
      'List & Loops': "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var n in numbers) {\n    print('Number: \$n');\n  }\n}",
      'Class Example': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, I am \$name');\n}\n\nvoid main() {\n  var p = Person('DartMini');\n  p.greet();\n}",
      'Async Example': "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data loaded!');\n}"
    };

    return AlertDialog(
      title: const Text('Examples Gallery', style: TextStyle(color: AppTheme.accentYellow)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: examples.entries.map((e) {
            return ListTile(
              title: Text(e.key, style: const TextStyle(color: AppTheme.textLight)),
              onTap: () {
                final newFile = FileModel(
                  id: const Uuid().v4(),
                  name: '${e.key.replaceAll(' ', '_').toLowerCase()}.dart',
                  content: e.value,
                );
                ref.read(fileProvider.notifier).addFile(newFile);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppTheme.textDim)),
        )
      ],
    );
  }
}
