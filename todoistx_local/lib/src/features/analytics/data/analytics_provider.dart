import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:collection/collection.dart';

class AnalyticsData {
  final List<int> weeklyCompletedTasks; // 7 days, today is the last element
  final int currentStreak;

  AnalyticsData({
    required this.weeklyCompletedTasks,
    required this.currentStreak,
  });
}

final analyticsProvider = Provider.autoDispose<AnalyticsData>((ref) {
  final tasks = ref.watch(tasksStreamProvider).asData?.value ?? [];
  final completedTasks = tasks.where((t) => t.isCompleted).toList();

  // Calculate weekly completed tasks
  final weeklyCompleted = List.filled(7, 0);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (final task in completedTasks) {
    final dateCompleted = DateTime(task.updatedAt.year, task.updatedAt.month, task.updatedAt.day);
    final dayDifference = today.difference(dateCompleted).inDays;
    if (dayDifference >= 0 && dayDifference < 7) {
      weeklyCompleted[6 - dayDifference]++;
    }
  }

  // Calculate current streak
  final completionDates = completedTasks
      .map((t) => DateTime(t.updatedAt.year, t.updatedAt.month, t.updatedAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a)); // Sort descending

  int streak = 0;
  if (completionDates.isNotEmpty) {
    if (completionDates.first.isAtSameMomentAs(today) ||
        completionDates.first.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      streak = 1;
      for (int i = 0; i < completionDates.length - 1; i++) {
        final day = completionDates[i];
        final nextDay = completionDates[i + 1];
        if (day.difference(nextDay).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
      // If the most recent completion was yesterday, and today has no completions, the streak is still valid.
      // If it was today, it's also valid.
      if (completionDates.first.isAtSameMomentAs(today.subtract(const Duration(days: 1))) && !completionDates.contains(today)) {
        // no-op, streak is correct
      }
    }
  }

  return AnalyticsData(
    weeklyCompletedTasks: weeklyCompleted,
    currentStreak: streak,
  );
});
