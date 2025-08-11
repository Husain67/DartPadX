import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';

class TaskListItem extends ConsumerWidget {
  const TaskListItem({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepository = ref.read(taskRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        notificationService.cancelTaskReminders(task);
        taskRepository.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${task.title} deleted')),
        );
      },
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) {
              if (value != null) {
                final updatedTask = Task(
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  createdAt: task.createdAt,
                  updatedAt: DateTime.now(),
                  dueDateTime: task.dueDateTime,
                  isCompleted: value,
                  priority: task.priority,
                  tags: task.tags,
                  projectId: task.projectId,
                  subtaskIds: task.subtaskIds,
                  imagePath: task.imagePath,
                  reminderTimes: task.reminderTimes,
                );
                taskRepository.updateTask(updatedTask);

                // If task is completed, cancel notifications
                if (value) {
                  notificationService.cancelTaskReminders(updatedTask);
                }
              }
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: task.dueDateTime != null
              ? Text(DateFormat.yMMMd().add_jm().format(task.dueDateTime!))
              : null,
          trailing: _buildTrailingWidgets(task),
        ),
      ),
    );
  }

  Widget? _buildPriorityIcon(int priority) {
    switch (priority) {
      case 1: // Medium
        return const Icon(Icons.flag, color: Colors.orange);
      case 2: // High
        return const Icon(Icons.flag, color: Colors.red);
      default: // Low or no priority
        return const SizedBox.shrink(); // Return an empty widget
    }
  }

  Widget _buildTrailingWidgets(Task task) {
    final List<Widget> children = [];
    if (task.imagePath != null) {
      children.add(const Icon(Icons.attachment, size: 16));
    }
    if (task.priority > 0) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 8));
      }
      children.add(_buildPriorityIcon(task.priority));
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
