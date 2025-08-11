import 'package:hive/hive.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/services/database_service.dart';

class TaskRepository {
  final Box<Task> _box;

  TaskRepository({required DatabaseService databaseService})
      : _box = databaseService.tasksBox;

  // Add a task
  // (एक कार्य जोड़ें)
  Future<void> addTask(Task task) async {
    await _box.put(task.id, task);
  }

  // Get a single task by id
  // (आईडी द्वारा एक कार्य प्राप्त करें)
  Task? getTask(String id) {
    return _box.get(id);
  }

  // Get all tasks
  // (सभी कार्य प्राप्त करें)
  List<Task> getAllTasks() {
    return _box.values.toList();
  }

  // Update a task
  // (एक कार्य को अपडेट करें)
  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task);
  }

  // Delete a task
  // (एक कार्य हटाएं)
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  // Watch for changes in the tasks box
  // (कार्य बॉक्स में परिवर्तनों के लिए देखें)
  Stream<List<Task>> watchTasks() {
    return _box.watch().map((_) => _box.values.toList());
  }
}
