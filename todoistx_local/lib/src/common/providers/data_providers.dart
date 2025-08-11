import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoistx_local/src/common/services/database_service.dart';
import 'package:todoistx_local/src/features/projects/data/project_repository.dart';
import 'package:todoistx_local/src/features/tags/data/tag_repository.dart';
import 'package:todoistx_local/src/features/tasks/data/task_repository.dart';
import 'package:todoistx_local/src/common/models/project.dart';
import 'package:todoistx_local/src/common/models/tag.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/services/image_service.dart';
import 'package:todoistx_local/src/common/services/notification_service.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoistx_local/src/common/theme/controllers/theme_controller.dart';
import 'package:todoistx_local/src/features/tasks/presentation/controllers/task_filter_controller.dart';

// A provider for the SharedPreferences instance.
// It is initialized in main.dart and overridden.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Provider for the ThemeController
final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeController(prefs);
});

// Provider for the ImageService
// (इमेज सर्विस के लिए प्रदाता)
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

// Provider for the NotificationService
// (अधिसूचना सेवा के लिए प्रदाता)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider for the DatabaseService singleton
// (डेटाबेस सर्विस सिंगलटन के लिए प्रदाता)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

// Provider for the TaskRepository
// (टास्क रिपोजिटरी के लिए प्रदाता)
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TaskRepository(databaseService: dbService);
});

// Provider for the ProjectRepository
// (प्रोजेक्ट रिपोजिटरी के लिए प्रदाता)
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ProjectRepository(databaseService: dbService);
});

// Provider for the TagRepository
// (टैग रिपोजिटरी के लिए प्रदाता)
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TagRepository(databaseService: dbService);
});

// The raw, unfiltered stream of tasks from the database.
final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  return taskRepo.watchTasks();
});

// A provider that returns a filtered and grouped list of tasks.
// (एक प्रदाता जो कार्यों की फ़िल्टर और समूहीकृत सूची लौटाता है।)
final groupedTasksProvider = Provider.autoDispose<Map<String, List<Task>>>((ref) {
  final tasks = ref.watch(tasksStreamProvider).asData?.value ?? [];
  final filter = ref.watch(taskFilterProvider);
  final projects = ref.watch(projectsProvider);

  // Apply filters
  final filtered = tasks.where((task) {
    final projectMatch = filter.projectId == null || task.projectId == filter.projectId;
    final tagMatch = filter.tagId == null || (task.tags?.contains(filter.tagId) ?? false);
    final priorityMatch = filter.priority == null || task.priority == filter.priority;
    return projectMatch && tagMatch && priorityMatch;
  }).toList();

  // Apply grouping
  switch (filter.groupBy) {
    case GroupBy.project:
      return groupBy(filtered, (Task t) {
        final project = projects.firstWhereOrNull((p) => p.id == t.projectId);
        return project?.name ?? 'No Project';
      });
    case GroupBy.priority:
      const priorityMap = {0: 'Low', 1: 'Medium', 2: 'High'};
      return groupBy(filtered, (Task t) => priorityMap[t.priority] ?? 'Low');
    case GroupBy.dueDate:
      return groupBy(filtered, (Task t) => t.dueDateTime?.toIso8601String().substring(0, 10) ?? 'No Due Date');
    case GroupBy.none:
    default:
      return {'All Tasks': filtered};
  }
});

// Provider to get the list of all projects
// (सभी परियोजनाओं की सूची प्राप्त करने के लिए प्रदाता)
final projectsProvider = Provider.autoDispose<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).getAllProjects();
});

// Provider to get the list of all tags
// (सभी टैग की सूची प्राप्त करने के लिए प्रदाता)
final tagsProvider = Provider.autoDispose<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).getAllTags();
});

// Provider to fetch a single task by ID. Used in the edit screen.
// (आईडी द्वारा एक कार्य लाने के लिए प्रदाता। संपादन स्क्रीन में उपयोग किया जाता है।)
final taskProvider = FutureProvider.autoDispose.family<Task?, String>((ref, id) {
  if (id == 'new') return null;
  return ref.watch(taskRepositoryProvider).getTask(id);
});

// StreamProvider for the list of projects
// (परियोजनाओं की सूची के लिए स्ट्रीमप्रदाता)
final projectsStreamProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final projectRepo = ref.watch(projectRepositoryProvider);
  return projectRepo.watchProjects();
});

// StreamProvider for the list of tags
// (टैग की सूची के लिए स्ट्रीमप्रदाता)
final tagsStreamProvider = StreamProvider.autoDispose<List<Tag>>((ref) {
  final tagRepo = ref.watch(tagRepositoryProvider);
  return tagRepo.watchTags();
});

// Provider to fetch a single project by ID.
final projectProvider = FutureProvider.autoDispose.family<Project?, String>((ref, id) {
  if (id == 'new') return null;
  return ref.watch(projectRepositoryProvider).getProject(id);
});

// Provider that groups tasks by date for the calendar view.
final calendarEventsProvider = Provider.autoDispose<Map<DateTime, List<Task>>>((ref) {
  final tasks = ref.watch(tasksStreamProvider).asData?.value ?? [];
  return groupBy(
    tasks.where((t) => t.dueDateTime != null),
    (Task task) => DateTime.utc(task.dueDateTime!.year, task.dueDateTime!.month, task.dueDateTime!.day),
  );
});

// Provider for tasks due today.
final todayTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final tasks = ref.watch(tasksStreamProvider).asData?.value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return tasks.where((task) {
    if (task.dueDateTime == null) return false;
    final dueDate = DateTime(task.dueDateTime!.year, task.dueDateTime!.month, task.dueDateTime!.day);
    return dueDate.isAtSameMomentAs(today);
  }).toList();
});
