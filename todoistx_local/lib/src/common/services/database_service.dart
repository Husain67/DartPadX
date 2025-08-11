import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoistx_local/src/common/models/project.dart';
import 'package:todoistx_local/src/common/models/tag.dart';
import 'package:todoistx_local/src/common/models/task.dart';

class DatabaseService {
  // Singleton pattern
  // (एकल पैटर्न)
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  late Box<Task> _tasksBox;
  late Box<Project> _projectsBox;
  late Box<Tag> _tagsBox;

  Box<Task> get tasksBox => _tasksBox;
  Box<Project> get projectsBox => _projectsBox;
  Box<Tag> get tagsBox => _tagsBox;

  static const String tasksBoxName = 'tasks';
  static const String projectsBoxName = 'projects';
  static const String tagsBoxName = 'tags';

  Future<void> init() async {
    // Initialize Hive
    // (Hive को प्रारंभ करें)
    await Hive.initFlutter();

    // Register Adapters
    // (एडेप्टर पंजीकृत करें)
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TagAdapter());

    // Open Boxes
    // (बक्से खोलें)
    _tasksBox = await Hive.openBox<Task>(tasksBoxName);
    _projectsBox = await Hive.openBox<Project>(projectsBoxName);
    _tagsBox = await Hive.openBox<Tag>(tagsBoxName);

    // Seed data for testing
    // (परीक्षण के लिए बीज डेटा)
    await _seedData();
  }

  Future<void> _seedData() async {
    if (_tasksBox.isEmpty) {
      // --- Seed Projects ---
      final projectPersonal = Project(id: 'p1', name: 'Personal', color: 0xFFF44336, icon: 'person');
      final projectWork = Project(id: 'p2', name: 'Work', color: 0xFF2196F3, icon: 'work');
      await _projectsBox.put(projectPersonal.id, projectPersonal);
      await _projectsBox.put(projectWork.id, projectWork);

      // --- Seed Tags ---
      final tagUrgent = Tag(id: 't1', name: 'Urgent');
      final tagHome = Tag(id: 't2', name: 'Home');
      await _tagsBox.put(tagUrgent.id, tagUrgent);
      await _tagsBox.put(tagHome.id, tagHome);

      // --- Seed Tasks ---
      final now = DateTime.now();
      final task1 = Task(
        id: 'task1',
        title: 'Buy groceries',
        description: 'Milk, Bread, Eggs, and Cheese',
        createdAt: now,
        updatedAt: now,
        dueDateTime: now.add(const Duration(days: 1)),
        isCompleted: false,
        priority: 2, // High
        projectId: projectPersonal.id,
        tags: [tagHome.id],
      );
      final task2 = Task(
        id: 'task2',
        title: 'Finish report for Q3',
        description: 'Need to finalize the financial report and send it to management.',
        createdAt: now,
        updatedAt: now,
        dueDateTime: now.add(const Duration(days: 3)),
        isCompleted: false,
        priority: 2, // High
        projectId: projectWork.id,
        tags: [tagUrgent.id],
      );
      final task3 = Task(
        id: 'task3',
        title: 'Call the doctor',
        createdAt: now,
        updatedAt: now,
        dueDateTime: now.add(const Duration(days: 2)),
        isCompleted: true,
        priority: 1, // Medium
        projectId: projectPersonal.id,
      );
      await _tasksBox.put(task1.id, task1);
      await _tasksBox.put(task2.id, task2);
      await _tasksBox.put(task3.id, task3);
    }
  }

  Future<void> close() async {
    await _tasksBox.close();
    await _projectsBox.close();
    await _tagsBox.close();
  }
}
