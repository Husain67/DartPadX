import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class ExamplesGallery extends ConsumerWidget {
  const ExamplesGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Text('Examples Gallery', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _buildExampleTile(context, ref, 'Hello World', '''
void main() {
  print("Hello, World!");
}
'''),
          _buildExampleTile(context, ref, 'Input/Output', '''
import 'dart:io';

void main() {
  print("Enter your name:");
  String? name = stdin.readLineSync();
  print("Hello, \$name!");
}
'''),
          _buildExampleTile(context, ref, 'List Operations', '''
void main() {
  var list = [1, 2, 3, 4, 5];
  var mapped = list.map((e) => e * 2);
  print(mapped.toList());
}
'''),
          _buildExampleTile(context, ref, 'Class Example', '''
class Person {
  String name;
  int age;
  Person(this.name, this.age);
  void describe() => print("\$name is \$age years old.");
}

void main() {
  var p = Person("Alice", 25);
  p.describe();
}
'''),
          _buildExampleTile(context, ref, 'Async Example', '''
Future<void> fetch() async {
  await Future.delayed(Duration(seconds: 1));
  print("Data fetched");
}

void main() async {
  print("Fetching data...");
  await fetch();
  print("Done.");
}
'''),
        ],
      ),
    );
  }

  Widget _buildExampleTile(BuildContext context, WidgetRef ref, String title, String code) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        ref.read(fileProvider.notifier).importFile('${title.replaceAll(" ", "_")}.dart', code);
        Navigator.pop(context);
      },
    );
  }
}
