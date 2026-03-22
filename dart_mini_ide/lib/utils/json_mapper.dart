class JsonMapper {
  /// Extracts a value from a JSON map using dot notation path
  /// e.g. path: "data.user.name"
  static dynamic getValueByPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;

    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else if (current is List) {
        // Simple array index support e.g. "data.users.0.name"
        final index = int.tryParse(key);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }
}
