import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesDialog extends ConsumerWidget {
  const ExamplesDialog({Key? key}) : super(key: key);

  static const Map<String, String> _examples = {
    'Hello World': '''void main() {
  print('Hello World!');
}''',
    'Input Output': '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
    'List': '''void main() {
  var list = [1, 2, 3];
  list.add(4);
  list.forEach((item) => print(item));
}''',
    'Class': '''class Person {
  String name;
  int age;
  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p = Person('Alice', 30);
  p.introduce();
}''',
    'Async': '''Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched!');
}'''
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Examples', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _examples.length,
          itemBuilder: (context, index) {
            String key = _examples.keys.elementAt(index);
            return ListTile(
              title: Text(key, style: const TextStyle(color: Colors.white70)),
              onTap: () {
                final safeKey = key.replaceAll(' ', '_');
                ref.read(fileProvider.notifier).addFile('${safeKey}.dart', _examples[key]!);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
