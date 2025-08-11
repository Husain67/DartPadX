import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 1)
class Project extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int color; // Store color as an integer

  @HiveField(3)
  late String icon; // Store icon identifier (e.g., from a specific icon pack)

  Project({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}
