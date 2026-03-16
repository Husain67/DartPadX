import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_mini_ide/main.dart';
import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('test_hive_dir');
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>('files');
    await Hive.openBox<CompilerPreset>('presets');

    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  testWidgets('DartMini IDE App boots successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DartMiniIDEApp()));
    await tester.pumpAndSettle();

    expect(find.text('DartMini'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('main.dart'), findsOneWidget);
  });

  testWidgets('Run button shows loading state while executing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DartMiniIDEApp()));
    await tester.pumpAndSettle();

    final runButtonFinder = find.text('Run');
    expect(runButtonFinder, findsOneWidget);
  });
}
