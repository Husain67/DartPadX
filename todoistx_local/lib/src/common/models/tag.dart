import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 2)
class Tag extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  Tag({
    required this.id,
    required this.name,
  });
}
