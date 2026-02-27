import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

class FileRepository {
  final Box<CodeFile> _box;
  final Uuid _uuid = const Uuid();

  FileRepository(this._box);

  List<CodeFile> getAllFiles() {
    if (_box.isEmpty) {
      // Create default file if empty
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print("Hello, DartMini IDE!");

  // Example: Standard Input
  // import 'dart:io';
  // String? input = stdin.readLineSync();
  // print("You entered: \$input");
}
''',
        lastModified: DateTime.now(),
      );
      _box.put(defaultFile.id, defaultFile);
      return [defaultFile];
    }
    return _box.values.toList()..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  CodeFile createFile({String? name, String? content}) {
    final file = CodeFile(
      id: _uuid.v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
      lastModified: DateTime.now(),
    );
    _box.put(file.id, file);
    return file;
  }

  Future<void> updateFile(CodeFile file) async {
    file.lastModified = DateTime.now();
    await _box.put(file.id, file);
  }

  Future<void> deleteFile(String id) async {
    await _box.delete(id);
  }
}
