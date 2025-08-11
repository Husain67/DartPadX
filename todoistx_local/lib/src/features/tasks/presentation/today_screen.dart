import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:todoistx_local/src/features/tasks/presentation/widgets/task_list_view.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(todayTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
      ),
      body: todayTasks.isEmpty
          ? const Center(child: Text('No tasks due today. Great job!'))
          : TaskListView(tasks: todayTasks),
    );
  }
}
