import yaml

with open('pubspec.yaml', 'r') as f:
    data = yaml.safe_load(f)

# The user asked for flutter_code_editor: ^0.2.0 (or latest for full IDE features).
# Memory note: flutter_code_editor ^0.3.2+ to fix deprecated subtitle1 usage.
# I'll use ^0.3.2.
# highlight: ^0.7.0 -> wait, memory says `flutter_highlight`. Pubspec dependency should be flutter_highlight.
# user asked for `highlight: ^0.7.0`. I'll add flutter_highlight too, but actually `flutter_highlight` requires `highlight` implicitly.
# memory says: "Key dependencies include flutter_code_editor (^0.3.2+ ...), flutter_riverpod, hive_flutter, http, dart_style, uuid, flutter_highlight, and file_picker."

dependencies = {
    'flutter': {'sdk': 'flutter'},
    'cupertino_icons': '^1.0.8',
    'flutter_code_editor': '^0.3.2',
    'flutter_highlight': '^0.7.0',
    'highlight': '^0.7.0',
    'riverpod': '^2.5.1',
    'flutter_riverpod': '^2.5.1',
    'hive': '^2.2.3',
    'hive_flutter': '^1.1.0',
    'http': '^1.2.2',
    'shared_preferences': '^2.3.0',
    'fluttertoast': '^8.2.8',
    'path_provider': '^2.1.4',
    'url_launcher': '^6.3.0',
    'share_plus': '^10.0.0',
    'file_picker': '^8.1.2',
    'flutter_markdown': '^0.7.4',
    'dart_style': '^3.1.7',
    'uuid': '^4.4.0'
}

data['dependencies'] = dependencies
data['environment']['sdk'] = '^3.5.0'

with open('pubspec.yaml', 'w') as f:
    yaml.dump(data, f, sort_keys=False)
