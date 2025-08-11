import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:todoistx_local/src/features/tasks/presentation/home_screen.dart';
import 'package:todoistx_local/l10n/app_localizations.dart';

void main() {
  final mockTasks = [
    Task(id: '1', title: 'Task 1', createdAt: DateTime.now(), updatedAt: DateTime.now(), isCompleted: false),
    Task(id: '2', title: 'Task 2', createdAt: DateTime.now(), updatedAt: DateTime.now(), isCompleted: false),
  ];

  testWidgets('HomeScreen displays title and tasks from provider', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the groupedTasksProvider to return a mock map
          groupedTasksProvider.overrideWithValue({'All Tasks': mockTasks}),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );

    // Verify the AppBar title is displayed.
    expect(find.text('All Tasks'), findsOneWidget);

    // Verify that the two tasks are displayed.
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
  });
}
