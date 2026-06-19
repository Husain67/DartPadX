import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_file.dart';
import '../providers/file_provider.dart';
import '../core/theme.dart';

class ExamplesScreen extends ConsumerWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'name': 'Hello World',
        'code': 'void main() {\n  print(\'Hello World!\');\n}',
      },
      {
        'name': 'Input Output',
        'code': 'import \'dart:io\';\n\nvoid main() {\n  print(\'Enter value:\');\n  var input = stdin.readLineSync();\n  print(\'You entered: \$input\');\n}',
      },
      {
        'name': 'Async Fetch',
        'code': 'Future<void> main() async {\n  print(\'Fetching...\');\n  await Future.delayed(const Duration(seconds: 1));\n  print(\'Done!\');\n}',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Examples')),
      backgroundColor: AppTheme.backgroundStart,
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final ex = examples[index];
          return ListTile(
            title: Text(ex['name']!, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.add, color: AppTheme.primaryAccent),
            onTap: () {
              final newName = ex['name']!.replaceAll(' ', '_').toLowerCase();
              final newFile = CodeFile(
                name: '\$newName.dart',
                content: ex['code']!,
              );
              ref.read(fileProvider.notifier).addFile(newFile);
              if (context.mounted) {
                Navigator.pop(context); // close examples
                Navigator.pop(context); // close settings
              }
            },
          );
        },
      ),
    );
  }
}
