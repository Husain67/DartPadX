import 'package:flutter_test/flutter_test.dart';
import 'package:dart_mini_ide/models/models.dart';

import 'package:dart_mini_ide/services/file_service.dart';

void main() {
  group('Models Tests', () {
    test('CodeFile copyWith works', () {
      final file = CodeFile(id: '1', name: 'main.dart', content: 'print(1);');
      final updated = file.copyWith(content: 'print(2);');
      expect(updated.content, 'print(2);');
      expect(updated.id, '1');
    });

    test('CompilerPreset json serialization works', () {
      final preset = CompilerPreset(
        id: 'p1',
        name: 'Test Preset',
        endpointUrl: 'http://test',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        stdoutPath: 'out',
        stderrPath: 'err',
        errorPath: 'err',
        executionTimePath: 'time',
        memoryPath: 'mem',
      );

      final json = preset.toJson();
      final decoded = CompilerPreset.fromJson(json);
      expect(decoded.id, 'p1');
      expect(decoded.name, 'Test Preset');
    });
  });

  group('Service Tests', () {
    test('FileService formats Dart code correctly', () {
      const code = '''void main(){print("test");}''';
      final formatted = FileService.formatCode(code);
      expect(formatted.contains('void main() {'), isTrue);
      expect(formatted.contains('  print("test");\n}'), isTrue);
    });

    test('FileService handles format syntax errors gracefully', () {
      const badCode = '''void main( {''';
      final formatted = FileService.formatCode(badCode);
      expect(formatted, badCode); // returns original on error
    });
  });
}
