import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  DateTime? dueDateTime;

  @HiveField(6)
  late bool isCompleted;

  @HiveField(7)
  late int priority; // 0: Low, 1: Medium, 2: High

  @HiveField(8)
  List<String>? tags;

  @HiveField(9)
  String? projectId;

  @HiveField(10)
  List<String>? subtaskIds;

  @HiveField(11)
  List<DateTime>? reminderTimes;

  @HiveField(12)
  String? imagePath;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.dueDateTime,
    this.isCompleted = false,
    this.priority = 0,
    this.tags,
    this.projectId,
    this.subtaskIds,
    this.reminderTimes,
    this.imagePath,
  });
}
