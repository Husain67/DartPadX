import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/main.dart';
import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/utils/constants.dart';

void main() {
  setUpAll(() async {
    // Initialize mock Hive environment for testing
    Hive.init('test_hive_db');
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>(AppConstants.hiveBoxFiles);
    await Hive.openBox<CompilerPreset>(AppConstants.hiveBoxPresets);
    await Hive.openBox(AppConstants.hiveBoxSettings);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('App initializes and renders MainScreen', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: DartMiniIDEApp()));
      await tester.pump();

      // Verify AppBar title is present
      expect(find.text('DartMini'), findsOneWidget);

      // Verify toolbar items
      expect(find.text('New File'), findsOneWidget);
    });
  });
}
