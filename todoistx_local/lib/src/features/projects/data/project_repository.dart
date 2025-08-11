import 'package:hive/hive.dart';
import 'package:todoistx_local/src/common/models/project.dart';
import 'package:todoistx_local/src/common/services/database_service.dart';

class ProjectRepository {
  final Box<Project> _box;

  ProjectRepository({required DatabaseService databaseService})
      : _box = databaseService.projectsBox;

  // Add a project
  // (एक प्रोजेक्ट जोड़ें)
  Future<void> addProject(Project project) async {
    await _box.put(project.id, project);
  }

  // Get a single project by id
  // (आईडी द्वारा एक प्रोजेक्ट प्राप्त करें)
  Project? getProject(String id) {
    return _box.get(id);
  }

  // Get all projects
  // (सभी प्रोजेक्ट प्राप्त करें)
  List<Project> getAllProjects() {
    return _box.values.toList();
  }

  // Update a project
  // (एक प्रोजेक्ट को अपडेट करें)
  Future<void> updateProject(Project project) async {
    await _box.put(project.id, project);
  }

  // Delete a project
  // (एक प्रोजेक्ट हटाएं)
  Future<void> deleteProject(String id) async {
    await _box.delete(id);
  }

  // Watch for changes in the projects box
  // (प्रोजेक्ट बॉक्स में परिवर्तनों के लिए देखें)
  Stream<List<Project>> watchProjects() {
    return _box.watch().map((_) => _box.values.toList());
  }
}
