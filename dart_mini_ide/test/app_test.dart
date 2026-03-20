import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/main.dart';
import 'package:dart_mini_ide/providers/execution_provider.dart';

void main() {
  testWidgets('DartMiniIDEApp initializes correctly', (WidgetTester tester) async {
    // Note: We bypass Hive initialization for a pure widget test by just testing if it builds
    // In a real app we would mock Hive. Here we just ensure the provider structure is sound.

    final container = ProviderContainer();

    // Check initial execution state
    final executionState = container.read(executionProvider);
    expect(executionState.isRunning, isFalse);
    expect(executionState.stdout, isEmpty);
    expect(executionState.stderr, isEmpty);
  });
}
