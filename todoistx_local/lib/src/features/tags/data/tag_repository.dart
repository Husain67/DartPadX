import 'package:hive/hive.dart';
import 'package:todoistx_local/src/common/models/tag.dart';
import 'package:todoistx_local/src/common/services/database_service.dart';

class TagRepository {
  final Box<Tag> _box;

  TagRepository({required DatabaseService databaseService})
      : _box = databaseService.tagsBox;

  // Add a tag
  // (एक टैग जोड़ें)
  Future<void> addTag(Tag tag) async {
    await _box.put(tag.id, tag);
  }

  // Get a single tag by id
  // (आईडी द्वारा एक टैग प्राप्त करें)
  Tag? getTag(String id) {
    return _box.get(id);
  }

  // Get all tags
  // (सभी टैग प्राप्त करें)
  List<Tag> getAllTags() {
    return _box.values.toList();
  }

  // Update a tag
  // (एक टैग को अपडेट करें)
  Future<void> updateTag(Tag tag) async {
    await _box.put(tag.id, tag);
  }

  // Delete a tag
  // (एक टैग हटाएं)
  Future<void> deleteTag(String id) async {
    await _box.delete(id);
  }

  // Watch for changes in the tags box
  // (टैग बॉक्स में परिवर्तनों के लिए देखें)
  Stream<List<Tag>> watchTags() {
    return _box.watch().map((_) => _box.values.toList());
  }
}
