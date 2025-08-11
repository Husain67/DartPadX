import 'package:flutter/material.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/features/tasks/presentation/widgets/task_list_item.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key, required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(task: task);
      },
    );
  }
}
