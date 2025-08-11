import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/l10n/app_localizations.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:todoistx_local/src/features/tasks/presentation/controllers/task_filter_controller.dart';
import 'package:todoistx_local/src/features/tasks/presentation/task_search_delegate.dart';
import 'package:todoistx_local/src/features/tasks/presentation/widgets/task_list_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedTasks = ref.watch(groupedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.allTasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: TaskSearchDelegate(ref));
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => const FilterSheet(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => GoRouter.of(context).go('/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => GoRouter.of(context).go('/settings'),
          ),
        ],
      ),
      body: groupedTasks.isEmpty
          ? const Center(child: Text('No tasks match the current filter.'))
          : GroupedTaskListView(groupedTasks: groupedTasks),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).go('/task/new'),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class GroupedTaskListView extends StatelessWidget {
  const GroupedTaskListView({super.key, required this.groupedTasks});
  final Map<String, List<Task>> groupedTasks;

  @override
  Widget build(BuildContext context) {
    final groupKeys = groupedTasks.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final groupName = groupKeys[index];
        final tasks = groupedTasks[groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
              child: Text(
                groupName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...tasks.map((task) => TaskListItem(task: task)),
            const Divider(),
          ],
        );
      },
    );
  }
}


class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final filterController = ref.read(taskFilterProvider.notifier);
    final projects = ref.watch(projectsProvider);
    final tags = ref.watch(tagsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Filter & Group', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          // Project Filter
          DropdownButtonFormField<String?>(
            value: filter.projectId,
            decoration: const InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Projects')),
              ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
            ],
            onChanged: (value) => filterController.setProject(value),
          ),
          const SizedBox(height: 16),
          // Tag Filter
          DropdownButtonFormField<String?>(
            value: filter.tagId,
            decoration: const InputDecoration(labelText: 'Tag', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Tags')),
              ...tags.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
            ],
            onChanged: (value) => filterController.setTag(value),
          ),
          const SizedBox(height: 16),
          // Priority Filter
          DropdownButtonFormField<int?>(
            value: filter.priority,
            decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Priorities')),
              DropdownMenuItem(value: 0, child: Text('Low')),
              DropdownMenuItem(value: 1, child: Text('Medium')),
              DropdownMenuItem(value: 2, child: Text('High')),
            ],
            onChanged: (value) => filterController.setPriority(value),
          ),
          const SizedBox(height: 16),
          // Group By
          DropdownButtonFormField<GroupBy>(
            value: filter.groupBy,
            decoration: const InputDecoration(labelText: 'Group By', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: GroupBy.none, child: Text('None')),
              DropdownMenuItem(value: GroupBy.project, child: Text('Project')),
              DropdownMenuItem(value: GroupBy.priority, child: Text('Priority')),
              DropdownMenuItem(value: GroupBy.dueDate, child: Text('Due Date')),
            ],
            onChanged: (value) => filterController.setGroupBy(value ?? GroupBy.none),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              filterController.clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Clear Filters'),
          )
        ],
      ),
    );
  }
}
