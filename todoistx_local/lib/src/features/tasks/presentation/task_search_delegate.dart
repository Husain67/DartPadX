import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';

class TaskSearchDelegate extends SearchDelegate<Task?> {
  final WidgetRef ref;

  TaskSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final allTasks = ref.watch(tasksStreamProvider).asData?.value ?? [];

    if (query.isEmpty) {
      return const Center(child: Text('Search for tasks by title or description.'));
    }

    final results = allTasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = task.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
      return titleMatch || descriptionMatch;
    }).toList();

    if (results.isEmpty) {
      return Center(child: Text('No tasks found for "$query"'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description ?? ''),
          onTap: () {
            close(context, task);
            GoRouter.of(context).go('/task/${task.id}');
          },
        );
      },
    );
  }
}
