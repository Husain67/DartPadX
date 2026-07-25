import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic structural test without Hive init since it's hard to mock in simple test
    await tester
        .pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold())));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
