import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:todoistx_local/src/features/analytics/data/analytics_provider.dart';

// Mock task data for testing
List<Task> createMockTasks() {
  final now = DateTime.now();
  return [
    // Completed today
    Task(id: '1', title: 't1', isCompleted: true, createdAt: now, updatedAt: now),
    // Completed yesterday
    Task(id: '2', title: 't2', isCompleted: true, createdAt: now, updatedAt: now.subtract(const Duration(days: 1))),
    // Completed 3 days ago
    Task(id: '3', title: 't3', isCompleted: true, createdAt: now, updatedAt: now.subtract(const Duration(days: 3))),
    // Completed 6 days ago
    Task(id: '4', title: 't4', isCompleted: true, createdAt: now, updatedAt: now.subtract(const Duration(days: 6))),
    // Completed 8 days ago (should not be in weekly chart)
    Task(id: '5', title: 't5', isCompleted: true, createdAt: now, updatedAt: now.subtract(const Duration(days: 8))),
    // Not completed
    Task(id: '6', title: 't6', isCompleted: false, createdAt: now, updatedAt: now),
  ];
}

void main() {
  group('analyticsProvider', () {
    test('calculates weekly completed tasks correctly', () {
      final container = ProviderContainer(
        overrides: [
          tasksStreamProvider.overrideWith((ref) => Stream.value(createMockTasks())),
        ],
      );

      final analyticsData = container.read(analyticsProvider);

      // Expected: [1, 0, 0, 1, 0, 1, 1]
      // Day 6 ago, 5 ago, 4 ago, 3 ago, 2 ago, yesterday, today
      expect(analyticsData.weeklyCompletedTasks[0], 1); // 6 days ago
      expect(analyticsData.weeklyCompletedTasks[1], 0);
      expect(analyticsData.weeklyCompletedTasks[2], 0);
      expect(analyticsData.weeklyCompletedTasks[3], 1); // 3 days ago
      expect(analyticsData.weeklyCompletedTasks[4], 0);
      expect(analyticsData.weeklyCompletedTasks[5], 1); // yesterday
      expect(analyticsData.weeklyCompletedTasks[6], 1); // today
      expect(analyticsData.weeklyCompletedTasks.reduce((a, b) => a + b), 4);
    });

    test('calculates current streak correctly', () {
      final container = ProviderContainer(
        overrides: [
          tasksStreamProvider.overrideWith((ref) => Stream.value(createMockTasks())),
        ],
      );

      final analyticsData = container.read(analyticsProvider);

      // Streak is 2 because tasks were completed today and yesterday
      expect(analyticsData.currentStreak, 2);
    });

    test('calculates streak correctly when there is a gap', () {
       final now = DateTime.now();
       final mockTasksWithGap = [
         Task(id: '1', title: 't1', isCompleted: true, createdAt: now, updatedAt: now),
         // Gap of one day
         Task(id: '2', title: 't2', isCompleted: true, createdAt: now, updatedAt: now.subtract(const Duration(days: 2))),
       ];

       final container = ProviderContainer(
        overrides: [
          tasksStreamProvider.overrideWith((ref) => Stream.value(mockTasksWithGap)),
        ],
      );

      final analyticsData = container.read(analyticsProvider);

      // Streak is 1 because there was a gap
      expect(analyticsData.currentStreak, 1);
    });
  });
}
