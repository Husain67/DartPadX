import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:todoistx_local/src/features/tasks/presentation/widgets/task_list_item.dart';
import 'package:mockito/mockito.dart';
import 'package:todoistx_local/src/common/services/notification_service.dart';
import 'package:todoistx_local/src/features/tasks/data/task_repository.dart';

// Mocks
class MockTaskRepository extends Mock implements TaskRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  final mockTaskRepository = MockTaskRepository();
  final mockNotificationService = MockNotificationService();

  final testTask = Task(
    id: '1',
    title: 'Test Task Title',
    isCompleted: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    priority: 1,
  );

  testWidgets('TaskListItem displays task title and checkbox', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskRepository),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TaskListItem(task: testTask),
          ),
        ),
      ),
    );

    // Verify that the task title is displayed.
    expect(find.text('Test Task Title'), findsOneWidget);

    // Verify that the checkbox is not checked.
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
  });

  testWidgets('tapping checkbox updates the task', (WidgetTester tester) async {
     await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskRepository),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TaskListItem(task: testTask),
          ),
        ),
      ),
    );

    // Tap the checkbox.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    // Verify that updateTask was called on the repository.
    // We use argThat to check the properties of the Task object passed.
    verify(mockTaskRepository.updateTask(argThat(
      isA<Task>()
          .having((t) => t.id, 'id', '1')
          .having((t) => t.isCompleted, 'isCompleted', true),
    ))).called(1);
  });
}
