import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_mini_ide/main.dart';
import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';

void main() {
  setUpAll(() async {
    // Setup Hive for testing
    Hive.init('./test_hive_db');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CodeFileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CompilerPresetAdapter());
    await Hive.openBox<CodeFile>('files');
    await Hive.openBox<CompilerPreset>('presets');
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('App initializes and builds main screen successfully', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: DartMiniIDEApp()));
      await tester.pumpAndSettle();

      // Verify basic UI elements are present
      expect(find.text('DartMini'), findsOneWidget);
      expect(find.text('Run'), findsOneWidget);
      expect(find.text('New File'), findsOneWidget);
      expect(find.text('Output Console'), findsOneWidget);
    });
  });
}
