import 'package:flutter_test/flutter_test.dart';
import 'package:dart_mini_ide/models/code_file.dart';

void main() {
  test('CodeFile instantiation', () {
    final file = CodeFile(
      id: '1',
      name: 'test.dart',
      content: 'void main() {}',
      lastModified: DateTime.now(),
    );
    expect(file.id, '1');
    expect(file.name, 'test.dart');
    expect(file.content, 'void main() {}');
  });
}
